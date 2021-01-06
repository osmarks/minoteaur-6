import karax/[karaxdsl, vdom]
import cmark/native
# the builtin re library would probably be better for this - it can directly take cstrings (so better perf when dealing with the cstrings from cmark) and may be faster
# unfortunately it does not expose a findAll thing which returns the *positions* of everything for some weird reason
import regex

cmark_gfm_core_extensions_ensure_registered()

func wikilink(page, linkText: string): string =
    let vdom = buildHtml(a(href=page, class="wikilink")): text linkText
    $vdom

proc pushNodeAfter(ty: NodeType, content: string, pushAfter: NodePtr) =
    let node = cmark_node_new(ty)
    assert cmark_node_set_literal(node, content) == 1
    assert cmark_node_insert_before(pushAfter, node) == 1

proc renderToHtml*(input: string): string =
    let wlRegex = re"\[\[([^:\]]+):?([^\]]+)?\]\]"
    let opt = CMARK_OPT_UNSAFE or CMARK_OPT_FOOTNOTES or CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE or CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES

    let
        str: cstring = input
        len: csize_t = len(input).csize_t
        parser: ParserPtr = cmark_parser_new(opt.cint)
    if parser == nil: raise newException(CatchableError, "failed to initialize parser")
    defer: cmark_parser_free(parser)

    for ext in @["table", "strikethrough"]:
        let e: cstring = ext
        let eptr = cmark_find_syntax_extension(e)
        if eptr == nil: raise newException(LibraryError, "failed to find extension " & ext)
        if cmark_parser_attach_syntax_extension(parser, eptr) == 0: raise newException(CatchableError, "failed to attach extension " & ext)

    cmark_parser_feed(parser, str, len)
    let doc = cmark_parser_finish(parser)
    defer: cmark_node_free(doc)
    if doc == nil: raise newException(CatchableError, "parsing failed")

    block:
        let iter = cmark_iter_new(doc)
        defer: cmark_iter_free(iter)
        while true:
            let evType = cmark_iter_next(iter)
            if evType == etDone: break
            let node: NodePtr = cmark_iter_get_node(iter)
            if cmark_node_get_type(node) == ntText:
                let ntext = $cmark_node_get_literal(node)
                # check for wikilinks in text node
                let matches = findAll(ntext, wlRegex)
                # if there are any, put in the appropriate HTML nodes
                if len(matches) > 0:
                    var lastix = 0
                    for match in matches:
                        let page = ntext[match.captures[0][0]] # I don't know why this doesn't use Option. Perhaps sometimes there are somehow > 1 ranges.
                        # if there is a separate linkText field, use this, otherwise just use the page
                        let linkText = 
                            if len(match.captures[1]) > 0: ntext[match.captures[1][0]]
                            else: page
                        let html = wikilink(page, linkText)
                        # push text before this onto the tree, as well as the HTML of the wikilink
                        pushNodeAfter(ntText, ntext[lastix..<match.boundaries.a], node)
                        pushNodeAfter(ntHtmlInline, html, node)
                        lastix = match.boundaries.b + 1
                    # push final text, if relevant
                    if lastix != len(ntext) - 1: pushNodeAfter(ntText, ntext[lastix..<len(ntext)], node)
                    cmark_node_free(node)

    let html: cstring = cmark_render_html(doc, opt.cint, cmark_parser_get_syntax_extensions(parser))
    defer: free(html)

    result = $html