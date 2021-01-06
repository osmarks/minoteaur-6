import prologue
import prologue/middlewares/staticfile
import karax/[karaxdsl, vdom]
import prologue/middlewares/sessions/signedcookiesession
from uri import decodeUrl, encodeUrl
import tiny_sqlite
import options
import times
import sugar
import strutils

from ./domain import nil
from ./md import nil

let
    env = loadPrologueEnv(".env")
    settings = newSettings(
        appName = "minoteaur",
        debug = env.getOrDefault("debug", true),
        port = Port(env.getOrDefault("port", 7600)),
        secretKey = env.getOrDefault("secretKey", "")
    )

func navButton(content: string, href: string, class: string): VNode = buildHtml(a(class="link-button " & class, href=href)): text content

func base(title: string, navItems: seq[VNode], bodyItems: VNode): string =
    let vnode = buildHtml(html):
        head:
            link(rel="stylesheet", href="/static/style.css")
            meta(charset="utf8")
            meta(name="viewport", content="width=device-width,initial-scale=1.0")
            title: text title
        body:
            main:
                nav:
                    for n in navItems: n
                tdiv(class="header"):
                    h1: text title
                bodyItems
    $vnode

domain.migrate(openDatabase("./minoteaur.sqlite3"))

type
    AppContext = ref object of Context
        db: DbConn

# store thread's DB connection
var db {.threadvar.}: Option[DbConn]

proc dbMiddleware(): HandlerAsync =
    result = proc(ctx: AppContext) {.async.} =
        # open new DB connection for thread if there isn't one
        if db.isNone:
            db = some openDatabase("./minoteaur.sqlite3")
            # close DB connection on thread exit
            onThreadDestruction(proc() = 
                try: db.get().close()
                except: discard)
        ctx.db = get db
        await switch(ctx)

proc displayTime(t: Time): string = t.format("uuuu-MM-dd HH:mm:ss", utc())

func pageUrlFor(ctx: AppContext, route: string, page: string, query: openArray[(string, string)] = @[]): string = ctx.urlFor(route, { "page": encodeUrl(page) }, query)
func pageButton(ctx: AppContext, route: string, page: string, label: string, query: openArray[(string, string)] = @[]): VNode = navButton(label, pageUrlFor(ctx, route, page, query), route)

proc edit(ctx: AppContext) {.async.} =
    let page = decodeUrl(ctx.getPathParams("page"))
    let pageData = domain.fetchPage(ctx.db, page)
    let html = 
        buildHtml(form(`method`="post", class="edit-form")):
            textarea(name="content"): text pageData.map(p => p.content).get("")
            input(`type`="submit", value="Save", name="action", class="save")
    let verb = if pageData.isSome: "Editing " else: "Creating "
    resp base(verb & page, @[pageButton(ctx, "view-page", page, "View"), pageButton(ctx, "page-revisions", page, "Revisions")], html)

proc revisions(ctx: AppContext) {.async.} =
    let page = decodeUrl(ctx.getPathParams("page"))
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
                        a(href=ctx.urlFor("view-page", { "page": encodeUrl(page) }, { "ts": domain.timestampToStr(rev.time) })):
                            text displayTime(rev.time)
                    td: text rev.meta.editDistance.map(x => $x).get("")
                    td: text rev.meta.size.map(x => formatSize(x)).get("")
                    td: text rev.meta.words.map(x => $x).get("")
    resp base("Revisions of " & page, @[pageButton(ctx, "view-page", page, "View"), pageButton(ctx, "edit-page", page, "Edit")], html)

proc handleEdit(ctx: AppContext) {.async.} =
    let page = decodeUrl(ctx.getPathParams("page"))
    domain.updatePage(ctx.db, page, ctx.getFormParams("content"))
    resp redirect(pageUrlFor(ctx, "view-page", page))

proc view(ctx: AppContext) {.async.} =
    let page = decodeUrl(ctx.getPathParams("page"))
    let rawRevision = ctx.getQueryParams("ts")
    let viewSource = ctx.getQueryParams("source") != ""
    let revisionTs = if rawRevision == "": none(Time) else: some domain.timestampToTime(parseInt rawRevision)
    let viewingOldRevision = revisionTs.isSome

    let pageData = domain.fetchPage(ctx.db, page, revisionTs)
    if pageData.isNone:
        resp redirect(pageUrlFor(ctx, "edit-page", page))
    else:
        let pageData = get pageData
        let mainBody = if viewSource: buildHtml(pre): text pageData.content else: verbatim md.renderToHtml(pageData.content)
        if revisionTs.isNone:
            let html =
                buildHtml(tdiv):
                    tdiv(class="timestamp"):
                        text "Updated "
                        text displayTime(pageData.updated)
                    tdiv(class="timestamp"): 
                        text "Created "
                        text displayTime(pageData.created)
                    tdiv(class="md"): mainBody
            resp base(page, @[pageButton(ctx, "edit-page", page, "Edit"), pageButton(ctx, "page-revisions", page, "Revisions")], html)
        else:
            let rts = get revisionTs
            let (next, prev) = domain.adjacentRevisions(ctx.db, page, rts)
            let html =
                buildHtml(tdiv):
                    tdiv(class="timestamp"):
                        text "As of "
                        text displayTime(rts)
                    tdiv(class="md"): mainBody
            var buttons = @[pageButton(ctx, "edit-page", page, "Edit"), pageButton(ctx, "page-revisions", page, "Revisions"), pageButton(ctx, "view-page", page, "Latest")]
            if next.isSome: buttons.add(pageButton(ctx, "next-page", page, "Next", { "ts": domain.timestampToStr (get next).time }))
            if prev.isSome: buttons.add(pageButton(ctx, "prev-page", page, "Previous", { "ts": domain.timestampToStr (get prev).time }))
            resp base(page, buttons, html)

proc favicon(ctx: Context) {.async.} = resp "bee"

proc index(ctx: Context) {.async.} = resp "bee(s)"

var app = newApp(settings = settings)
app.use(@[staticFileMiddleware("static"), sessionMiddleware(settings), extendContextMiddleware(AppContext), dbMiddleware()])
app.get("/", index)
app.get("/favicon.ico", favicon)
app.get("/{page}/edit", edit, name="edit-page")
app.get("/{page}/revisions", revisions, name="page-revisions")
app.post("/{page}/edit", handleEdit, name="handle-edit")
app.get("/{page}/", view, name="view-page")
app.run()