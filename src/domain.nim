import tiny_sqlite
import logging
import options
import times
import zstd/compress as zstd_compress
import zstd/decompress as zstd_decompress
import sequtils
import strutils except splitWhitespace
import json
import std/jsonutils
import nimlevenshtein
import sugar
import unicode
import math

import ./util
from ./md import parsePage

let migrations = @[
    #[
    `pages` stores the content of all pages, as well as when they were last updated and created - this is all the information needed to render the current version of a page
    It's mildly inefficient space-wise to store the latest content here AND in the revisions table (in compressed form), but dealing with this better would probably require complex logic elsewhere
    which I don't think is worth it - I anticipate that media files will be much bigger, and probably significant amounts of old revisions (it would be worth investigating storing compact diffs).

    `revisions` stores all changes to a page, with metadata as JSON (messagepack is generally better, but SQLite can only query JSON) and optionally a separate blob storing larger associated data
    (currently, the entire page content, zstd-compressed)

    rowids (INTEGER PRIMARY KEY) are explicitly extant here due to FTS external content requiring them to be stable to work but are not to be used much.

    Links' toPage is not a foreign key as it's valid for the page to not exist.
    ]#
    """
CREATE TABLE pages (
    uid INTEGER PRIMARY KEY,
    page TEXT NOT NULL UNIQUE,
    updated INTEGER NOT NULL,
    created INTEGER NOT NULL,
    content TEXT NOT NULL
);
CREATE TABLE revisions (
    uid INTEGER PRIMARY KEY,
    page TEXT NOT NULL REFERENCES pages(page),
    timestamp INTEGER NOT NULL,
    meta TEXT NOT NULL,
    fullData BLOB
);
    """,
    """
CREATE VIRTUAL TABLE pages_fts USING fts5 (
    page, content,
    tokenize='porter unicode61 remove_diacritics 2',
    content=pages, content_rowid=uid
);
    """,
    """
CREATE TABLE links (
    uid INTEGER PRIMARY KEY,
    fromPage TEXT NOT NULL REFERENCES pages(page),
    toPage TEXT NOT NULL,
    linkText TEXT NOT NULL,
    context TEXT NOT NULL,
    UNIQUE (fromPage, toPage)
);
    """,
    """
CREATE TABLE files (
    uid INTEGER PRIMARY KEY,
    page TEXT NOT NULL REFERENCES pages(page),
    filename TEXT NOT NULL,
    storagePath TEXT NOT NULL,
    mimeType TEXT NOT NULL,
    metadata TEXT NOT NULL,
    uploadedTime INTEGER NOT NULL,
    UNIQUE (page, filename)
);
    """,
    """
CREATE TABLE sessions (
    sid INTEGER PRIMARY KEY,
    timestamp INTEGER NOT NULL,
    data TEXT NOT NULL
);
    """
]

type
    Encoding* {.pure.} = enum
        Plain = 0, Zstd = 1
    RevisionType* {.pure.} = enum
        NewContent = 0
    RevisionMeta* = object
        case kind*: RevisionType
        of NewContent:
            encoding*: Encoding
            editDistance*: Option[int]
            size*: Option[int]
            words*: Option[int]
    Revision* = object
        meta*: RevisionMeta
        time*: Time
    SearchResult* = object
        page*: string
        rank*: float
        snippet*: seq[(bool, string)]
    Page* = object
        page*, content*: string
        created*, updated*: Time
        uid*: int64
    Backlink* = object
        fromPage*, text*, context*: string
    FileInfo* = object
        filename*, mimeType*: string
        uploadedTime*: Time
        metadata*: JsonNode

proc migrate*(db: DbConn) =
    let currentVersion = fromDbValue(get db.value("PRAGMA user_version"), int)
    for mid in (currentVersion + 1) .. migrations.len:
        db.transaction:
            logger().log(lvlInfo, "Migrating to schema " & $mid)
            db.execScript migrations[mid - 1]
            # for some reason this pragma does not work using normal parameter binding
            db.exec("PRAGMA user_version = " & $mid)
    logger().log(lvlDebug, "DB ready")

proc parse*(s: string, T: typedesc): T = fromJson(result, parseJSON(s), Joptions(allowExtraKeys: true, allowMissingKeys: true))

proc processFullRevisionRow(row: ResultRow): (RevisionMeta, string) =
    let (metaJSON, full) = row.unpack((string, seq[byte]))
    let meta = parse(metaJSON, RevisionMeta)
    var content = cast[string](full)
    if meta.encoding == Zstd:
        content = cast[string](zstd_decompress.decompress(content))
    (meta, content)

proc fetchPage*(db: DbConn, page: string): Option[Page] =
    # retrieve the current version of the page directly
    db.one("SELECT uid, updated, created, content FROM pages WHERE page = ?", page).map(proc(row: ResultRow): Page =
        let (uid, updated, created, content) = row.unpack((int64, Time, Time, string))
        Page(page: page, created: created, updated: updated, content: content, uid: uid)
    )

proc fetchPage*(db: DbConn, page: string, revision: Time): Option[Page] =
    # retrieve page row
    db.one("SELECT uid, updated, created FROM pages WHERE page = ?", page).flatMap(proc(row: ResultRow): Option[Page] =
        let (uid, updated, created) = row.unpack((int64, Time, Time))
        # retrieve the older revision
        let rev = db.one("SELECT meta, fullData FROM revisions WHERE page = ? AND json_extract(meta, '$.kind') = 0 AND timestamp = ?", page, revision)
        rev.map(proc(row: ResultRow): Page =
            let (meta, content) = processFullRevisionRow(row)
            Page(page: page, created: created, updated: updated, content: content, uid: uid)
        )
    )

proc backlinks*(db: DbConn, page: string): seq[Backlink] =
    db.all("SELECT fromPage, linkText, context FROM links WHERE toPage = ?", page).map(proc(row: ResultRow): Backlink =
        let (fromPage, text, context) = row.unpack((string, string, string))
        Backlink(fromPage: fromPage, text: text, context: context))

# count words, defined as things separated by whitespace which are not purely Markdown-ish punctuation characters
# alternative definitions may include dropping number-only words, and/or splitting at full stops too
func wordCount(s: string): int =
    for word in splitWhitespace(s):
        if len(word) == 0: continue
        for bytechar in word: 
            if not (bytechar in {'#', '*', '-', '>', '`', '|', '+', '[', ']'}):
                inc result
                break

proc updatePage*(db: DbConn, page: string, content: string) =
    let parsed = parsePage(content)
    let previous = fetchPage(db, page)
    # if there is no previous content, empty string instead
    let previousContent = previous.map(p => p.content).get("")

    # use zstandard-compressed version if it is smaller
    let compressed = zstd_compress.compress(content, level=10)
    var enc = Plain
    var data = cast[seq[byte]](content)
    if len(compressed) < len(data):
        enc = Zstd
        data = compressed

    # generate some useful metadata and encode to JSON
    let meta = $toJson(RevisionMeta(kind: NewContent, encoding: enc, 
        editDistance: some distance(previousContent, content), size: some len(content), words: some wordCount(content)))
    let ts = getTime()

    let revisionID = snowflake()
    let pageID = previous.map(p => p.uid).get(snowflake())
    # actually write to database
    db.transaction:
        if isSome previous:
            # update existing data and remove FTS index entry for it
            db.exec("UPDATE pages SET content = ?, updated = ? WHERE uid = ?", content, ts, pageID)
            # pages_fts is an external content FTS table, so deletion has to be done like this
            db.exec("INSERT INTO pages_fts (pages_fts, rowid, page, content) VALUES ('delete', ?, ?, ?)", pageID, page, previousContent)
            # delete existing links from the page
            db.exec("DELETE FROM links WHERE fromPage = ?", page)
        else:
            db.exec("INSERT INTO pages VALUES (?, ?, ?, ?, ?)", pageID, page, ts, ts, content)
        # push to full text search index - TODO perhaps use the parsed text content (as used for context) instead of the raw markdown
        db.exec("INSERT INTO pages_fts (rowid, page, content) VALUES (?, ?, ?)", pageID, page, content)
        db.exec("INSERT INTO revisions VALUES (?, ?, ?, ?, ?)", revisionID, page, ts, meta, data)
        # insert new set of links
        for link in parsed.links:
            db.exec("INSERT INTO links VALUES (?, ?, ?, ?, ?)", snowflake(), page, link.target, link.text, link.context)

proc fetchRevisions*(db: DbConn, page: string): seq[Revision] =
    db.all("SELECT timestamp, meta FROM revisions WHERE page = ? ORDER BY timestamp DESC", page).map(proc (row: ResultRow): Revision =
        let (ts, metaJSON) = row.unpack((Time, string))
        Revision(time: ts, meta: parse(metaJSON, RevisionMeta))
    )

proc processRevisionRow(r: ResultRow): Revision =
    let (ts, meta) = r.unpack((Time, string))
    Revision(time: ts, meta: parse(meta, RevisionMeta))

proc adjacentRevisions*(db: DbConn, page: string, ts: Time): (Option[Revision], Option[Revision]) =
    # revision after given timestamp
    let next = db.one("SELECT timestamp, meta FROM revisions WHERE page = ? AND json_extract(meta, '$.kind') = 0 AND timestamp > ? ORDER BY timestamp ASC LIMIT 1", page, ts)
    # revision before given timestamp
    let prev = db.one("SELECT timestamp, meta FROM revisions WHERE page = ? AND json_extract(meta, '$.kind') = 0 AND timestamp < ? ORDER BY timestamp DESC LIMIT 1", page, ts)
    (next.map(processRevisionRow), prev.map(processRevisionRow))

proc processSearchRow(row: ResultRow): SearchResult =
    let (page, rank, snippet) = row.unpack((string, float, string))
    var pos = 0
    # split snippet up into an array of highlighted/unhighlighted bits
    var snips: seq[(bool, string)] = @[]
    while true:
        let newpos = find(snippet, "<hlstart>", pos)
        if newpos == -1:
            break
        snips.add((false, snippet[pos .. newpos - 1]))
        var endpos = find(snippet, "<hlend>", newpos)
        # if no <hlend> (this *probably* shouldn't happen) then just highlight remaining rest of string
        if endpos == -1:
            endpos = len(snippet)
        snips.add((true, snippet[newpos + len("<hlstart>") .. endpos - 1]))
        pos = endpos + len("<hlend>")
    snips.add((false, snippet[pos .. len(snippet) - 1]))
    # filter out empty snippet fragments because they're not useful, rescale rank for nicer display
    SearchResult(page: page, rank: log10(-rank * 1e7), snippet: snips.filter(x => len(x[1]) > 0))

proc search*(db: DbConn, query: string): seq[SearchResult] =
    db.all("SELECT page, rank, snippet(pages_fts, 1, '<hlstart>', '<hlend>', ' ... ', 32) FROM pages_fts WHERE pages_fts MATCH ? AND rank MATCH 'bm25(5.0, 1.0)' ORDER BY rank", query).map(processSearchRow)

proc getBasicFileInfo*(db: DbConn, page, filename: string): Option[(string, string)] =
    db.one("SELECT storagePath, mimeType FROM files WHERE page = ? AND filename = ?", page, filename).map(proc (r: ResultRow): (string, string) = r.unpack((string, string)))

proc getPageFiles*(db: DbConn, page: string): seq[FileInfo] =
    db.all("SELECT filename, mimeType, uploadedTime, metadata FROM files WHERE page = ?", page).map(proc (r: ResultRow): FileInfo = 
        let (filename, mime, upload, meta) = r.unpack((string, string, Time, string))
        FileInfo(filename: filename, mimetype: mime, uploadedTime: upload, metadata: parse(meta, JsonNode)))