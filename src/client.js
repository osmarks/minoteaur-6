import m from "mithril"
import { openDB } from "idb"
import { lightFormat } from "date-fns"

const dbPromise = openDB("minoteaur", 1, {
    upgrade: (db, oldVersion) => {
        if (oldVersion < 1) { db.createObjectStore("drafts") }
    },
    blocking: () => { window.location.reload() }
});
// debugging thing
dbPromise.then(x => { window.idb = x })

const searchState = {
    showingSearchDialog: false,
    searchResults: [],
    searchError: null,
    searchQuery: ""
}

const lowercaseFirst = ([first, ...rest]) => first.toLowerCase() + rest.join("")
const uppercaseFirst = ([first, ...rest]) => first.toUpperCase() + rest.join("")
const pageToSlug = page => page.split(/[ _]/).map(lowercaseFirst).join("_")
const slugToPage = slug => slug.split(/[ _]/).map(uppercaseFirst).join(" ")

const urlForPage = (page, subpage) => {
    let p = `/${encodeURIComponent(pageToSlug(page))}`
    if (subpage) { p += "/" + subpage }
    return p
}

const handleHTTPError = e => {
    window.lastError = e
    console.warn(e)
    let x = `HTTP error ${e.code}`
    if (e.message !== null) { x += " " + e.message }
    searchState.searchError = x
}

const onsearch = ev => {
    const query = ev.target.value
    searchState.searchQuery = query
    m.request({
        url: "/api/search",
        params: { q: query }
    }).then(x => {
        if (typeof x === "string") { // error from server
            console.warn(x)
            searchState.searchError = x
        } else {
            searchState.searchResults = x
            searchState.searchError = null
        }
    }, handleHTTPError)
}

const currentPage = slugToPage(decodeURIComponent(/^\/([^/]+)/.exec(location.pathname)[1]).replace(/\+/g, " "))

const searchKeyHandler = ev => {
    if (ev.code === "Enter") { // enter key
        // not very useful to just navigate to the same page
        const otherResults = searchState.searchResults.filter(r => r.page !== currentPage)
        if (otherResults[0]) { location.href = urlForPage(otherResults[0].page) }
    }
}

const SearchDialog = {
    view: () => m(".dialog.search", [
        m("h1", "Search"),
        m("input[type=search]", { placeholder: "Query", oninput: onsearch, onkeydown: searchKeyHandler, value: searchState.searchQuery, oncreate: ({ dom }) => dom.focus() }),
        searchState.searchError && m(".error", searchState.searchError),
        m("ul", searchState.searchResults.map(x => m("li", [
            m(".flex-space", [ m("a.wikilink", { href: urlForPage(x.page) }, x.page), m("", x.rank.toFixed(3)) ]),
            m("", x.snippet.map(s => s[0] ? m("span.highlight", s[1]) : s[1]))
        ])))
    ])
}

const SearchApp = {
    view: () => m("", searchState.showingSearchDialog ? m(SearchDialog) : null)
}

const mountpoint = document.createElement("div")
document.querySelector("main").insertBefore(mountpoint, document.querySelector(".header"))
m.mount(mountpoint, SearchApp)

const searchButton = document.querySelector("nav .search")

searchButton.addEventListener("click", e => {
    searchState.showingSearchDialog = !searchState.showingSearchDialog
    e.preventDefault()
    m.redraw()
})

// basic keyboard shortcuts - search, switch to view/edit/revs
document.body.addEventListener("keydown", e => {
    if (e.target === document.body) { // detect only unfocused keypresses - ctrl+key seems to cause issues when copy/pasting
        if (e.key === "e") {
            location.pathname = urlForPage(currentPage, "edit")
        } else if (e.key === "v") {
            location.pathname = urlForPage(currentPage)
        } else if (e.key === "r") {
            location.pathname = urlForPage(currentPage, "revisions")
        } else if (e.key === "/") {
            searchState.showingSearchDialog = !searchState.showingSearchDialog
            e.preventDefault()
            m.redraw()
        }
    }
})

const debounce = (fn, timeout = 250) => {
    let timer;
    return () => {
        clearTimeout(timer)
        timer = setTimeout(fn, timeout)
    }
}

const dispDateTime = dt => lightFormat(dt, "yyyy-MM-dd HH:mm:ss")

const wordCount = s => {
    let words = 0
    for (const possibleWord of s.split(/\s+/)) {
        if (/[^#*+>|`-]/.test(possibleWord)) { words += 1 }
    }
    return words
}
const lineCount = s => s.split("\n").length

const editor = document.querySelector(".edit-form textarea")
if (editor) {
    const editorUIState = {
        keypresses: 0,
        draftSelected: false
    }
    const mountpoint = document.createElement("div")
    document.querySelector(".sidebar").appendChild(mountpoint)

    // automatic resize of textareas upon typing
    // this is slightly "efficient" in that it avoids constantly setting the height to 0 and back in a few situations, which is seemingly quite expensive
    let lengthWas = Infinity
    const resize =  () => {
        const scrolltop = document.body.scrollTop
        const targetHeight = editor.scrollHeight + 2
        if (targetHeight != editor.style.height.slice(0, -2) || lengthWas > editor.value.length) {
            editor.style.height = 0
            editor.style.height = editor.scrollHeight + 2
            document.body.scrollTop = scrolltop
        }
        lengthWas = editor.value.length
    }

    // retrieve last edit timestamp from field
    const lastEditTime = parseInt(document.querySelector("input[name=last-edit]").value)
    const serverValue = editor.value

    // load in the initially loaded draft
    const swapInDraft = () => {
        if (!editorUIState.initialDraft) { return }
        editorUIState.draftSelected = true
        editor.value = editorUIState.initialDraft.text
        resize()
    }
    // load in the initial page from the server
    const swapInServer = () => {
        console.log("server value swapped in, allegedly?")
        editorUIState.draftSelected = false
        console.log(editor.value, serverValue)
        editor.value = serverValue
        resize()
    }

    dbPromise.then(db => db.get("drafts", currentPage)).then(draft => {
        editorUIState.initialDraft = draft
        console.log("loaded memetic/beemetic entity ", draft)
        // if the draft is newer than the server page, load it in (the user can override this)
        if (draft.ts > lastEditTime) {
            swapInDraft()
        }
        m.redraw()
    })

    const DraftInfo = {
        view: () => editorUIState.initialDraft == null ? "No draft" : [
            m(editorUIState.draftSelected ? ".selected" : "", { onclick: swapInDraft }, `Draft from ${dispDateTime(editorUIState.initialDraft.ts)}`),
            lastEditTime > 0 && m(editorUIState.draftSelected ? "" : ".selected", { onclick: swapInServer }, `Page from ${dispDateTime(lastEditTime)}`)
        ]
    }

    const EditorUIApp = {
        view: () => [
            m("", `${editorUIState.chars} chars`),
            m("", `${editorUIState.words} words`),
            m("", `${editorUIState.lines} lines`),
            m("", `${editorUIState.keypresses} keypresses`),
            m(DraftInfo)
        ]
    }

    const updateCounts = text => {
        editorUIState.words = wordCount(text)
        editorUIState.lines = lineCount(text)
        editorUIState.chars = text.length // incorrect for some unicode, but doing it correctly would be more complex and slow
    }
    updateCounts(editor.value)

    m.mount(mountpoint, EditorUIApp)

    editor.addEventListener("keypress", ev => {
        const selStart = editor.selectionStart
        const selEnd = editor.selectionEnd
        if (selStart !== selEnd) return // text is actually selected; these shortcuts are not meant for that situation

        const search = "\n" + editor.value.substr(0, selStart)
        const lastLineStart = search.lastIndexOf("\n") + 1 // drop the \n
        const nextLineStart = selStart + (editor.value.substr(selStart) + "\n").indexOf("\n")

        if (ev.code === "Enter") { // enter
            // save on ctrl+enter
            if (ev.ctrlKey) {
                editor.parentElement.submit()
                return
            }

            const line = search.substr(lastLineStart)
            // detect lists on the previous line to continue on the next one
            const match = /^(\s*)(([*+-])|(\d+)([).]))(\s*)/.exec(line)
            if (match) {
                // if it is an unordered list, just take the bullet type + associated whitespace
                // if it is an ordered list, increment the number and take the dot/paren and whitespace
                const lineStart = match[1] + (match[4] ? (parseInt(match[4]) + 1).toString() + match[5] : match[2]) + match[6]
                // get everything after the cursor on the same line
                const contentAfterCursor = editor.value.slice(selStart, nextLineStart)
                // all the content of the textbox preceding where the cursor should now be
                const prev = editor.value.substr(0, selStart) + "\n" + lineStart
                // update editor
                editor.value = prev + contentAfterCursor + editor.value.substr(nextLineStart)
                editor.selectionStart = editor.selectionEnd = prev.length
                resize()
                ev.preventDefault()
            }
        }
    })
    editor.addEventListener("keydown", ev => {
        const selStart = editor.selectionStart
        const selEnd = editor.selectionEnd
        if (selStart !== selEnd) return

        const search = "\n" + editor.value.substr(0, selStart)
        // this is missing the + 1 that the enter key listener has. I forgot why. Good luck working out this!
        const lastLineStart = search.lastIndexOf("\n")
        const nextLineStart = selStart + (editor.value.substr(selStart) + "\n").indexOf("\n")
        if (ev.code === "Backspace") {
            // detect if backspacing the start of a list line
            const re = /^\s*([*+-]|\d+[).])\s*$/y
            if (re.test(editor.value.slice(lastLineStart, selStart))) {
                // if so, remove entire list line start at once
                const before = editor.value.substr(0, lastLineStart)
                const after = editor.value.substr(selStart)
                editor.value = before + after
                editor.selectionStart = editor.selectionEnd = before.length
                resize()
                ev.preventDefault()
            }
        } else if (ev.code === "Tab") {
            // indent/dedent lists by 2 spaces, depending on shift key
            const match = /^(\s*)([*+-]|\d+[).])/.exec(editor.value.slice(lastLineStart, nextLineStart))
            let line = editor.value.substr(lastLineStart)
            if (ev.shiftKey) {
                line = line.replace(/^  /, "")
            } else {
                line = "  " + line
            }
            if (match) {
                editor.value = editor.value.substr(0, lastLineStart) + line
                editor.selectionStart = editor.selectionEnd = selStart + (ev.shiftKey ? -2 : 2)
                resize()
                ev.preventDefault()
            }
        }

        editorUIState.keypresses++
        m.redraw()
    })

    const saveDraft = debounce(() => {
        dbPromise.then(idb => idb.put("drafts", { text: editor.value, ts: Date.now() }, currentPage))
        console.log("saved")
    })

    editor.addEventListener("input", () => {
        resize()
        updateCounts(editor.value)
        saveDraft()
    })
    resize()
}