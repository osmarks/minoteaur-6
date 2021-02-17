import times
import unicode
import strutils except splitWhitespace
import sequtils
import tiny_sqlite
import random
import math
import times
import options

func lowercaseFirstLetter(s: string): string =
    if len(s) == 0:
        return ""
    var
        rune: Rune
        i = 0
    fastRuneAt(s, i, rune, doInc = true)
    result = $toLower(rune) & substr(s, i)
func pageToSlug*(page: string): string = page.split({'_', ' '}).map(lowercaseFirstLetter).join("_")
func slugToPage*(slug: string): string = slug.split({'_', ' '}).map(capitalize).join(" ")

func timeToTimestamp*(t: Time): int64 = toUnix(t) * 1000 + (nanosecond(t) div 1000000)
func timestampToTime*(ts: int64): Time = initTime(ts div 1000, (ts mod 1000) * 1000000)
func timestampToStr*(t: Time): string = intToStr(int(timeToTimestamp(t)))

# store time as milliseconds
proc toDbValue*(t: Time): DbValue = DbValue(kind: sqliteInteger, intVal: timeToTimestamp(t))
proc fromDbValue*(value: DbValue, T: typedesc[Time]): Time = timestampToTime(value.intVal)

template autoInitializedThreadvar*(name: untyped, typ: typedesc, initialize: typed): untyped =
    var data* {.threadvar.}: Option[typ] 
    proc `name`(): typ =
        if isSome(data): result = get data
        else:
            result = initialize
            data = some result

# https://github.com/aisk/simpleflake.nim/blob/master/src/simpleflake.nim - unique 64-bit timestamped ID generation
# not actually identical to that as this has 2 bits less randomness to avoid timestamp overflow issues in 2034 (the application is likely to be replaced by 2139 so the new time is probably fine)
# This is a signed integer for SQLite compatibility
const SIMPLEFLAKE_EPOCH = 946702800
const SIMPLEFLAKE_RANDOM_LENGTH = 21

let now = times.getTime()
var rng {.threadvar.}: Rand 
var rngInitialized {.threadvar.}: bool 

proc snowflake*(): int64 =
    if not rngInitialized:
        rng = random.initRand((now.toUnix * 1_000_000_000 + now.nanosecond) xor getThreadId())
        rngInitialized = true
    let now = times.getTime().toUnixFloat()
    var ts = int64((now - SIMPLEFLAKE_EPOCH) * 1000)
    let randomBits = int64(rng.rand(2 ^ SIMPLEFLAKE_RANDOM_LENGTH))

    return ts shl SIMPLEFLAKE_RANDOM_LENGTH or randomBits