import prologue
import prologue/middlewares/staticfile
import karax/[karaxdsl, vdom]
from uri import decodeUrl, encodeUrl
import tiny_sqlite
import options
import times
import sugar
import std/jsonutils
import strutils
import logging

from ./domain import nil
from ./md import nil
import ./util
import ./sqlitesession

let env = loadPrologueEnv(".env")
let settings = newSettings(
    appName = "minoteaur",
    debug = env.getOrDefault("debug", true),
    port = Port(env.getOrDefault("port", 7600)),
    secretKey = env.get("secretKey")
)
const dbPath = "./minoteaur.sqlite3" # TODO: work out gcsafety issues in making this runtime-configurable

func navButton(content: string, href: string, class: string): VNode = buildHtml(a(class="link-button " & class, href=href)): text content
func searchButton(): VNode = buildHtml(a(class="link-button search", href="")): text "Search"

func base(title: string, navItems: seq[VNode], bodyItems: VNode, sidebar: Option[VNode] = none(VNode)): string =
    let sidebarClass = if sidebar.isSome: "has-sidebar" else: ""
    let vnode = buildHtml(html):
        head:
            link(rel="stylesheet", href="/static/style.css")
            script(src="/static/client.js", `defer`="defer")
            meta(charset="utf-8")
            meta(name="viewport", content="width=device-width,initial-scale=1.0")
            title: text title
        body:
            main(class=sidebarClass):
                nav:
                    for n in navItems: n
                tdiv(class="header"):
                    h1: text title
                bodyItems
            if sidebar.isSome: tdiv(class="sidebar"): get sidebar
    "<!DOCTYPE html>" & $vnode

proc openDBConnection(): DbConn =
    logger().log(lvlInfo, "Opening database connection")
    let conn = openDatabase(dbPath)
    conn.exec("PRAGMA foreign_keys = ON")
    return conn

autoInitializedThreadvar(db, DbConn, openDBConnection())

block:
    let db = openDatabase(dbPath)
    domain.migrate(db)
    close(db())

proc dbMiddleware(): HandlerAsync =
    result = proc(ctx: AppContext) {.async.} =        
        ctx.db = db()
        await switch(ctx)

proc headersMiddleware(): HandlerAsync =
    result = proc(ctx: AppContext) {.async.} =
        await switch(ctx)
        ctx.response.setHeader("X-Content-Type-Options", "nosniff")
        # user-controlled inline JS/CSS is explicitly turned on
        # this does partly defeat the point of a CSP, but this is still able to prevent connecting to other sites unwantedly
        ctx.response.setHeader("Content-Security-Policy", "default-src 'self' 'unsafe-inline'; img-src * data:; media-src * data:; form-action 'self'; frame-ancestors 'self'")
        ctx.response.setHeader("Referrer-Policy", "origin-when-cross-origin")

proc requireLoginMiddleware(): HandlerAsync =
    result = proc(ctx: AppContext) {.async.} =
        let loginURL = ctx.urlFor("login-page")
        let authed = ctx.session.getOrDefault("authed", "f")
        let path = ctx.request.path
        if authed == "t" or path == loginURL or path.startsWith("/static"):
            await switch(ctx)
        else:
            let loginRedirectURL = ctx.urlFor("login-page", queryParams={ "redirect": path })
            resp redirect(loginRedirectURL, Http303)

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
            # pass inputs to JS-side editor code as hidden input fields
            # TODO: this is somewhat horrible, do another thing
            input(`type`="hidden", value=pageData.map(p => timestampToStr(p.updated)).get("0"), name="last-edit")
            input(`type`="hidden", value= $toJson(domain.getPageFiles(ctx.db, page)), name="associated-files")
    let sidebar = buildHtml(tdiv):
        input(`type`="submit", value="Save", name="action", class="save", form="edit-form")
    let verb = if pageData.isSome: "Editing " else: "Creating "
    resp base(verb & page, @[searchButton(), pageButton(ctx, "view-page", page, "View"), pageButton(ctx, "page-revisions", page, "Revisions")], html, some(sidebar))

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
    resp base("Revisions of " & page, @[searchButton(), pageButton(ctx, "view-page", page, "View"), pageButton(ctx, "edit-page", page, "Edit")], html)

proc handleEdit(ctx: AppContext) {.async.} =
    let page = slugToPage(decodeUrl(ctx.getPathParams("page")))
    # file upload instead of content change
    if "file" in ctx.request.formParams.data:
        let file = ctx.request.formParams["file"]
        echo $file
        await ctx.respond(Http204, "")
    else:
        domain.updatePage(ctx.db, page, ctx.getFormParams("content"))
        resp redirect(pageUrlFor(ctx, "view-page", page), Http303)

proc sendAttachedFile(ctx: AppContext) {.async.} =
    let page = slugToPage(decodeUrl(ctx.getPathParams("page")))
    let filename = decodeUrl(ctx.getPathParams("filename"))
    let filedata = domain.getBasicFileInfo(ctx.db, page, filename)
    if filedata.isSome:
        let (path, mime) = get filedata
        await ctx.staticFileResponse(path, "", mimetype = mime)
    else:
        resp error404()

proc view(ctx: AppContext) {.async.} =
    try:
        ctx.session["counter"] = $(parseInt(ctx.session["counter"]) + 1)
    except:
        ctx.session["counter"] = "2"
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
            
            resp base(page, @[searchButton(), pageButton(ctx, "edit-page", page, "Edit"), pageButton(ctx, "page-revisions", page, "Revisions")], html)

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
            var buttons = @[searchButton(), pageButton(ctx, "edit-page", page, "Edit"), pageButton(ctx, "page-revisions", page, "Revisions"), pageButton(ctx, "view-page", page, "Latest")]
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

proc loginPage(ctx: AppContext) {.async.} =
    let options = @["I forgot my password", "I remembered it, but then bees stole it", "I am actively unable to remember anything", "I know it, but can't enter it", "I know it, but won't enter it",
        "I know it, but am not alive/existent enough to enter it", "I remembered my password", "I forgot my password", "My password was retroactively erased/altered", "All of the above",
        "My password contains anomalous Unicode I cannot type", "I forgot my keyboard", "My password is unrepresentable within Unicode", "My password is unrepresentable within reality",
        "I am not actually the intended user and I don't know the password", "I'm bored and clicking on random options", "Contingency λ-8288 is to be initiated", "One of the above, but username instead",
        "The box is too small", "The box is too big", "There's not even a username option", "I cannot type (in general)", "I want backdoor access", "I forgot to forget my password",
        "I forgot my username", "I remembered a password, but the wrong one", "My password cannot safely be entered", "My password's length exceeds available memory", 
        "I don't know the password but can get it if I can log in now", "I'm bored and clicking on nondeterministic options", "I dislike these options", "I like these options",
        "I remembered to forget my password", "I don't like my password", "My password cannot be reused due to linear types", "I would like to forget my password but I am incapable of doing so",
        "My password is sapient and refuses to be typed", "My password anomalously causes refusal of authentication", "I cannot legally provide my password", "I lack required insurance",
        "I am aware of all information in the universe except my password", "I am unable to read", "My password is infohazardous", "My password might be infohazardous", "I forgot your password",
        "My password anomalously refuses changes", "My password cannot be trusted", "My password forgot me", "My password has been garbage-collected", "I don't trust the site with my password",
        "My identity was forcefully separated from my password", "My issue defies characterization", "I cannot send HTTP POST requests", "My password contains my password",
        "I am legally required to enter my password but engaging in rebellion", "My password is the nontrivial zeros of the Riemann zeta function", "My password is the string of bytes required to crash this webserver",
        "My password is my password only when preceded by my password", "Someone is watching me enter my password", "I am legally required to click this option", "My password takes infinite time to evaluate",
        "I neither remembered nor forgot my password", "I forgot the concept of passwords", "I reject the concept of passwords"]
    let html = buildHtml(tdiv):
        form(`method`="post", class="login"):
            input(`type`="password", placeholder="Password")
            input(`type`="submit", class="login", value="Login")

        h2: text "Extra login options"
        ul:
            for option in options:
                li: a(href=""): text option
    resp base("Login", @[], html)

proc handleLogin(ctx: AppContext) {.async.} =
    let success = true
    # TODO: This does allow off-site redirects. Fix this.
    # Also TODO: rate limiting
    if success:
        logger().log(lvlInfo, "Successful login")
        ctx.session["authed"] = "t"
        resp redirect(ctx.request.queryParams.getOrDefault("redirect", "/"), Http303)
    else: 
        logger().log(lvlInfo, "Unsuccessful login")
        resp redirect(ctx.urlFor("login-page"), Http303)

proc favicon(ctx: Context) {.async.} = resp error404()
proc index(ctx: Context) {.async.} = resp "TODO"

var app = newApp(settings = settings)
app.use(@[staticFileMiddleware("static"), extendContextMiddleware(AppContext), dbMiddleware(), sessionMiddleware(settings, db), requireLoginMiddleware(), headersMiddleware()])
app.get("/", index)
app.get("/favicon.ico", favicon)
app.get("/login", loginPage, name="login-page")
app.post("/login", handleLogin, name="handle-login")
app.get("/api/search", search, name="search")
app.get("/{page}/edit", edit, name="edit-page")
app.get("/{page}/revisions", revisions, name="page-revisions")
app.post("/{page}/edit", handleEdit, name="handle-edit")
app.get("/{page}/file/{filename}", sendAttachedFile, name="send-attached-file")
app.get("/{page}/", view, name="view-page")
app.run()