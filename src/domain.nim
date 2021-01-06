import tiny_sqlite
import logging
import options
import times
import zstd/compress
import zstd/decompress
import sequtils
import strutils except splitWhitespace
import json
import std/jsonutils
import nimlevenshtein
import sugar
import unicode

func timeToTimestamp*(t: Time): int64 = toUnix(t) * 1000 + (nanosecond(t) div 1000000)
func timestampToTime*(ts: int64): Time = initTime(ts div 1000, (ts mod 1000) * 1000000)
func timestampToStr*(t: Time): string = intToStr(int(timeToTimestamp(t)))

# store time as milliseconds
proc toDbValue(t: Time): DbValue = DbValue(kind: sqliteInteger, intVal: timeToTimestamp(t))
proc fromDbValue(value: DbValue, T: typedesc[Time]): Time = timestampToTime(value.intVal)

let migrations = @[
    """CREATE TABLE pages (
        page TEXT NOT NULL PRIMARY KEY,
        updated INTEGER NOT NULL,
        created INTEGER NOT NULL
    );
    CREATE TABLE revisions (
        page TEXT NOT NULL REFERENCES pages(page),
        timestamp INTEGER NOT NULL,
        meta TEXT NOT NULL,
        fullData BLOB
    );"""
]

type
    Encoding = enum
        encPlain = 0, encZstd = 1
    RevisionType = enum
        rtNewContent = 0
    RevisionMeta = object
        case typ*: RevisionType
        of rtNewContent:
            encoding*: Encoding
            editDistance*: Option[int]
            size*: Option[int]
            words*: Option[int]

    Revision = object
        meta*: Revisionmeta
        time*: Time

var logger = newConsoleLogger()

proc migrate*(db: DbConn) =
    let currentVersion = fromDbValue(get db.value("PRAGMA user_version"), int)
    for mid in (currentVersion + 1) .. migrations.len:
        db.transaction:
            logger.log(lvlInfo, "Migrating to schema " & $mid)
            db.execScript migrations[mid - 1]
            # for some reason this pragma does not work using normal parameter binding
            db.exec("PRAGMA user_version = " & $mid)
    logger.log(lvlDebug, "DB ready")

type 
    Page = object
        page*, content*: string
        created*, updated*: Time

proc parse*(s: string, T: typedesc): T = fromJson(result, parseJSON(s), Joptions(allowExtraKeys: true, allowMissingKeys: true))

proc processFullRevisionRow(row: ResultRow): (RevisionMeta, string) =
    let (metaJSON, full) = row.unpack((string, seq[byte]))
    let meta = parse(metaJSON, RevisionMeta)
    var content = cast[string](full)
    if meta.encoding == encZstd:
        content = cast[string](decompress(content))
    (meta, content)

proc fetchPage*(db: DbConn, page: string, revision: Option[Time] = none(Time)): Option[Page] =
    # retrieve row for page
    db.one("SELECT updated, created FROM pages WHERE page = ?", page).flatMap(proc(row: ResultRow): Option[Page] =
        let (updated, created) = row.unpack((Time, Time))
        let rev =
            if revision.isSome: db.one("SELECT meta, fullData FROM revisions WHERE page = ? AND json_extract(meta, '$.typ') = 0 AND timestamp = ?", page, revision)
            else: db.one("SELECT meta, fullData FROM revisions WHERE page = ? AND json_extract(meta, '$.typ') = 0 ORDER BY timestamp DESC LIMIT 1", page)
        rev.map(proc(row: ResultRow): Page =
            let (meta, content) = processFullRevisionRow(row)
            Page(page: page, created: created, updated: updated, content: content)
        )
    )

# count words, defined as things separated by whitespace which are not purely Markdown-ish punctuation characters
# alternative definitions may include dropping number-only words, and/or splitting at full stops too
func wordCount(s: string): int =
    for word in splitWhitespace(s):
        if len(word) == 0: continue
        for bytechar in word: 
            if not (bytechar in {'#', '*', '-', '>', '`', '|', '-'}):
                inc result
                break

proc updatePage*(db: DbConn, page: string, content: string) =
    let previous = fetchPage(db, page).map(p => p.content).get("")

    let compressed = compress(content, level=10)
    var enc = encPlain
    var data = cast[seq[byte]](content)
    if len(compressed) < len(data):
        enc = encZstd
        data = compressed

    let meta = $toJson(RevisionMeta(typ: rtNewContent, encoding: enc, 
        editDistance: some distance(previous, content), size: some len(content), words: some wordCount(content)))
    let ts = getTime()

    db.transaction:
        db.exec("INSERT INTO revisions VALUES (?, ?, ?, ?)", page, ts, meta, data)
        db.exec("INSERT INTO pages VALUES (?, ?, ?) ON CONFLICT (page) DO UPDATE SET updated = ?", page, ts, ts, ts)

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
    let next = db.one("SELECT timestamp, meta FROM revisions WHERE page = ? AND json_extract(meta, '$.typ') = 0 AND timestamp > ? ORDER BY timestamp ASC LIMIT 1", page, ts)
    # revision before given timestamp
    let prev = db.one("SELECT timestamp, meta FROM revisions WHERE page = ? AND json_extract(meta, '$.typ') = 0 AND timestamp < ? ORDER BY timestamp DESC LIMIT 1", page, ts)
    (next.map(processRevisionRow), prev.map(processRevisionRow))