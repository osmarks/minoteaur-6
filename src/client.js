import m from "mithril"

const searchButton = document.querySelector("nav .search")
const mountpoint = document.createElement("div")
document.querySelector("main").insertBefore(mountpoint, document.querySelector(".header"))

const state = {
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
    if (e.code === 0) { return }
    let x = `Server error ${e.code}`
    if (e.message) { x += " " + e.message }
    alert(x)
}

const onsearch = ev => {
    const query = ev.target.value
    state.searchQuery = query
    m.request({
        url: "/api/search",
        params: { q: query }
    }).then(x => {
        if (typeof x === "string") { // SQLite syntax error
            console.log("ERR", x)
            state.searchError = x
        } else {
            state.searchResults = x
            state.searchError = null
        }
    }, e => handleHTTPError)
}

const currentPage = slugToPage(decodeURIComponent(/^\/([^/]+)/.exec(location.pathname)[1]).replace(/\+/g, " "))

const searchKeyHandler = ev => {
    if (ev.keyCode === 13) { // enter key
        // not very useful to just navigate to the same page
        const otherResults = state.searchResults.filter(r => r.page !== currentPage)
        if (otherResults[0]) { location.href = urlForPage(otherResults[0].page) }
    }
}

const SearchDialog = {
    view: () => m(".dialog.search", [
        m("h1", "Search"),
        m("input[type=search]", { placeholder: "Query", oninput: onsearch, onkeydown: searchKeyHandler, value: state.searchQuery, oncreate: ({ dom }) => dom.focus() }),
        state.searchError && m(".error", state.searchError),
        m("ul", state.searchResults.map(x => m("li", [
            m(".flex-space", [ m("a.wikilink", { href: urlForPage(x.page) }, x.page), m("", x.rank.toFixed(3)) ]),
            m("", x.snippet.map(s => s[0] ? m("span.highlight", s[1]) : s[1]))
        ])))
    ])
}

const App = {
    view: () => m("", state.showingSearchDialog ? m(SearchDialog) : null)
}

searchButton.addEventListener("click", e => {
    state.showingSearchDialog = !state.showingSearchDialog
    e.preventDefault()
    m.redraw()
})

document.body.addEventListener("keydown", e => {
    if (e.target === document.body) { // maybe use alt instead? or right shift or something - this just detects unfocused keypresses
        if (e.key === "e") {
            location.pathname = urlForPage(currentPage, "edit")
        } else if (e.key === "v") {
            location.pathname = urlForPage(currentPage)
        } else if (e.key === "r") {
            location.pathname = urlForPage(currentPage, "revisions")
        } else if (e.key === "/") {
            state.showingSearchDialog = !state.showingSearchDialog
            e.preventDefault()
            m.redraw()
        }
    }
})

m.mount(mountpoint, App)