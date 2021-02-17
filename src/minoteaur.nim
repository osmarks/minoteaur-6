import prologue
import prologue/middlewares/staticfile
import karax/[karaxdsl, vdom]
import prologue/middlewares/sessions/signedcookiesession
from uri import decodeUrl, encodeUrl
import tiny_sqlite
import options
import times
import sugar
import std/jsonutils
import strutils

from ./domain import nil
from ./md import nil
import util

let
    env = loadPrologueEnv(".env")
    settings = newSettings(
        appName = "minoteaur",
        debug = env.getOrDefault("debug", true),
        port = Port(env.getOrDefault("port", 7600)),
        secretKey = env.getOrDefault("secretKey", "")
    )

func navButton(content: string, href: string, class: string): VNode = buildHtml(a(class="link-button " & class, href=href)): text content

func base(title: string, navItems: seq[VNode], bodyItems: VNode, sidebar: Option[VNode] = none(VNode)): string =
    let sidebarClass = if sidebar.isSome: "has-sidebar" else: ""
    let vnode = buildHtml(html):
        head:
            link(rel="stylesheet", href="/static/style.css")
            script(src="/static/client.js", `defer`="true")
            meta(charset="utf8")
            meta(name="viewport", content="width=device-width,initial-scale=1.0")
            title: text title
        body:
            main(class=sidebarClass):
                nav:
                    a(class="link-button search", href=""): text "Search"
                    for n in navItems: n
                tdiv(class="header"):
                    h1: text title
                bodyItems
            if sidebar.isSome: tdiv(class="sidebar"): get sidebar
    $vnode

block:
    let db = openDatabase("./minoteaur.sqlite3")
    domain.migrate(db)
    close(db)

type
    AppContext = ref object of Context
        db: DbConn

# store thread's DB connection
var db {.threadvar.}: Option[DbConn]

proc dbMiddleware(): HandlerAsync =
    # horrible accursed hack to make exitproc work
    result = proc(ctx: AppContext) {.async.} =
        # open new DB connection for thread if there isn't one
        if db.isNone:
            echo "Opening database connection"
            var conn = openDatabase("./minoteaur.sqlite3")
            conn.exec("PRAGMA foreign_keys = ON")
            db = some conn
        ctx.db = get db
        await switch(ctx)

proc headersMiddleware(): HandlerAsync =
    result = proc(ctx: AppContext) {.async.} =
        await switch(ctx)
        ctx.response.setHeader("X-Content-Type-Options", "nosniff")
        # user-controlled inline JS/CSS is explicitly turned on
        # this does partly defeat the point of a CSP, but this is still able to prevent connecting to other sites unwantedly
        ctx.response.setHeader("Content-Security-Policy", "default-src 'self' 'unsafe-inline'; img-src * data:; media-src * data:; form-action 'self'; frame-ancestors 'self'")
        ctx.response.setHeader("Referrer-Policy", "origin-when-cross-origin")

proc displayTime(t: Time): string = t.format("uuuu-MM-dd HH:mm:ss", utc())

func pageUrlFor(ctx: AppContext, route: string, page: string, query: openArray[(string, string)] = @[]): string = ctx.urlFor(route, { "page": encodeUrl(pageToSlug(page)) }, query)
func pageButton(ctx: AppContext, route: string, page: string, label: string, query: openArray[(string, string)] = @[]): VNode = navButton(label, pageUrlFor(ctx, route, page, query), route)

proc edit(ctx: AppContext) {.async.} =
    let page = slugToPage(decodeUrl(ctx.getPathParams("page")))
    let pageData = domain.fetchPage(ctx.db, page)
    let html =
        # autocomplete=off disables some sort of session history caching mechanism which interferes with draft handling
        buildHtml(form(`method`="post", class="edit-form", id="edit-form", autocomplete="off")):
            textarea(name="content"): text pageData.map(p => p.content).get("")
            input(`type`="hidden", value=pageData.map(p => timestampToStr(p.updated)).get("0"), name="last-edit")
    let sidebar = buildHtml(tdiv):
        input(`type`="submit", value="Save", name="action", class="save", form="edit-form")
    let verb = if pageData.isSome: "Editing " else: "Creating "
    resp base(verb & page, @[pageButton(ctx, "view-page", page, "View"), pageButton(ctx, "page-revisions", page, "Revisions")], html, some(sidebar))

proc revisions(ctx: AppContext) {.async.} =
    let page = slugToPage(decodeUrl(ctx.getPathParams("page")))
    let revs = domain.fetchRevisions(ctx.db, page)
    let html = 
        buildHtml(table(class="rev-table")):
            tr:
                th: text "Time"
                th: text "Changes"
                th: text "Size"
                th: text "Words"
            for rev in revs:
                tr: 
                    td(class="ts"):
                        a(href=ctx.urlFor("view-page", { "page": pageToSlug(encodeUrl(page)) }, { "ts": timestampToStr(rev.time) })):
                            text displayTime(rev.time)
                    td: text rev.meta.editDistance.map(x => $x).get("")
                    td: text rev.meta.size.map(x => formatSize(x)).get("")
                    td: text rev.meta.words.map(x => $x).get("")
    resp base("Revisions of " & page, @[pageButton(ctx, "view-page", page, "View"), pageButton(ctx, "edit-page", page, "Edit")], html)

proc handleEdit(ctx: AppContext) {.async.} =
    let page = slugToPage(decodeUrl(ctx.getPathParams("page")))
    domain.updatePage(ctx.db, page, ctx.getFormParams("content"))
    resp redirect(pageUrlFor(ctx, "view-page", page), Http303)

proc sendAttachedFile(ctx: AppContext) {.async.} =
    let page = slugToPage(decodeUrl(ctx.getPathParams("page")))
    echo "orbital bee strike → you"
    resp "TODO"

proc view(ctx: AppContext) {.async.} =
    let page = slugToPage(decodeUrl(ctx.getPathParams("page")))
    let rawRevision = ctx.getQueryParams("ts")
    let viewSource = ctx.getQueryParams("source") != ""
    let revisionTs = if rawRevision == "": none(Time) else: some timestampToTime(parseInt rawRevision)
    let viewingOldRevision = revisionTs.isSome

    let pageData = if viewingOldRevision: domain.fetchPage(ctx.db, page, get revisionTs) else: domain.fetchPage(ctx.db, page)
    if pageData.isNone:
        resp redirect(pageUrlFor(ctx, "edit-page", page), Http302)
    else:
        let pageData = get pageData
        let mainBody = if viewSource: buildHtml(pre): text pageData.content else: verbatim md.renderToHtml(pageData.content)
        if revisionTs.isNone:
            # current revision
            let backlinks = domain.backlinks(ctx.db, page)
            let html =
                buildHtml(tdiv):
                    tdiv(class="timestamp"):
                        text "Updated "
                        text displayTime(pageData.updated)
                    tdiv(class="timestamp"): 
                        text "Created "
                        text displayTime(pageData.created)
                    tdiv(class="md"): mainBody
                    if backlinks.len > 0:
                        h2: text "Backlinks"
                        ul(class="backlinks"):
                            for backlink in backlinks:
                                li:
                                    tdiv: a(class="wikilink", href=pageUrlFor(ctx, "view-page", backlink.fromPage)): text backlink.fromPage
                                    tdiv: text backlink.context
            
            resp base(page, @[pageButton(ctx, "edit-page", page, "Edit"), pageButton(ctx, "page-revisions", page, "Revisions")], html)

        else:
            # old revision
            let rts = get revisionTs
            let (next, prev) = domain.adjacentRevisions(ctx.db, page, rts)
            let html =
                buildHtml(tdiv):
                    tdiv(class="timestamp"):
                        text "As of "
                        text displayTime(rts)
                    tdiv(class="md"): mainBody
            var buttons = @[pageButton(ctx, "edit-page", page, "Edit"), pageButton(ctx, "page-revisions", page, "Revisions"), pageButton(ctx, "view-page", page, "Latest")]
            if next.isSome: buttons.add(pageButton(ctx, "next-page", page, "Next", { "ts": timestampToStr (get next).time }))
            if prev.isSome: buttons.add(pageButton(ctx, "prev-page", page, "Previous", { "ts": timestampToStr (get prev).time }))

            resp base(page, buttons, html)

proc search(ctx: AppContext) {.async.} =
    let query = ctx.getQueryParams("q")
    var results: seq[domain.SearchResult] = @[]
    try:
        if query != "": results = domain.search(ctx.db, query)
    except SqliteError as e: # SQLite apparently treats FTS queries containing some things outside of quotes as syntax errors. These should probably be shown to the user.
        resp jsonResponse toJson($e.msg)
        return
    resp jsonResponse toJson(results)

proc favicon(ctx: Context) {.async.} = resp error404()
proc index(ctx: Context) {.async.} = resp "bee(s)"

var app = newApp(settings = settings)
app.use(@[staticFileMiddleware("static"), sessionMiddleware(settings), extendContextMiddleware(AppContext), dbMiddleware(), headersMiddleware()])
app.get("/", index)
app.get("/favicon.ico", favicon)
app.get("/api/search", search, name="search")
app.get("/{page}/edit", edit, name="edit-page")
app.get("/{page}/revisions", revisions, name="page-revisions")
app.post("/{page}/edit", handleEdit, name="handle-edit")
app.get("/{page}/file/{filename}", sendAttachedFile, name="send-attached-file")
app.get("/{page}/", view, name="view-page")
app.run()