# based on https://github.com/planety/prologue/blob/devel/src/prologue/middlewares/sessions/redissession.nim
# SQLite session storage adapter

import std/[options, strtabs, asyncdispatch]

from prologue/core/types import len, Session, newSession, loads, dumps
from prologue/core/context import Context, HandlerAsync, getCookie, setCookie, deleteCookie
from prologue/core/response import addHeader
from prologue/core/middlewaresbase import switch
from prologue/core/nativesettings import Settings
from cookiejar import SameSite
from strutils import parseBiggestInt
import tiny_sqlite
import times

import ./util

proc sessionMiddleware*(
    settings: Settings,
    getDB: (proc(): DbConn),
    sessionName = "session",
    maxAge: int = 14 * 24 * 60 * 60, # 14 days, in seconds
    domain = "",
    sameSite = Lax,
    httpOnly = false
): HandlerAsync =
    return proc(ctx: Context) {.async.} =
        # TODO: this may be invoking dark gods slightly (fix?)
        # the proc only accesses the DB threadvar, but it itself is GC memory
        {.gcsafe.}:
            let db = getDB()
        var sessionIDString = ctx.getCookie(sessionName)

        # no session ID results in sessionIDString being empty, which will also result in a parse failure
        # this will cause a new session ID to be generated
        var sessionID: int64 = -1
        try:
            sessionID = int64(parseBiggestInt sessionIDString)
        except ValueError: discard

        var sessionTS = getTime()

        if sessionID != -1:
            # fetch session from database
            let info = db.one("SELECT * FROM sessions WHERE sid = ?", sessionID)
            if info.isSome:
                let (sid, ts, data) = info.get().unpack((int64, Time, string))
                sessionTS = ts
                ctx.session = newSession(data = newStringTable(modeCaseSensitive))
                ctx.session.loads(data)
            else:
                ctx.session = newSession(data = newStringTable(modeCaseSensitive))
        else:
            ctx.session = newSession(data = newStringTable(modeCaseSensitive))

            sessionID = snowflake()
            ctx.setCookie(sessionName, $sessionID, maxAge = some(maxAge), domain = domain, sameSite = sameSite, httpOnly = httpOnly)

        await switch(ctx)

        if ctx.session.len == 0: # empty or modified (del or clear)
            if ctx.session.modified: # modified
                db.exec("DELETE FROM sessions WHERE sid = ?", sessionID)
                ctx.deleteCookie(sessionName, domain = domain) # delete session data in cookie
                return

        if ctx.session.accessed:
            ctx.response.addHeader("Vary", "Cookie")

        if ctx.session.modified:
            let serializedSessionData = ctx.session.dumps()
            db.exec("INSERT OR REPLACE INTO sessions VALUES (?, ?, ?)", sessionID, sessionTS, serializedSessionData)
            # garbage collect old sessions
            # TODO: consider checking elsewhere, as not doing so leads to a bit of an exploit where
            # old session IDs can be used for a while
            let oldSessionThreshold = getTime() + initDuration(seconds = -maxAge)
            db.exec("DELETE FROM sessions WHERE timestamp < ?", oldSessionThreshold)