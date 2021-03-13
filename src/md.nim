import karax/[karaxdsl, vdom]
import cmark/native as cmark except Node, Parser
# the builtin re library would probably be better for this - it can directly take cstrings (so better perf when dealing with the cstrings from cmark) and may be faster
# unfortunately it does not expose a findAll thing which returns the *positions* of everything for some weird reason
import regex
from strutils import join, find, startsWith, endsWith
import unicode
import sets

from ./util import pageToSlug, slugToPage, autoInitializedThreadvar

cmark_gfm_core_extensions_ensure_registered()

type
    Node = object
        raw: NodePtr
    BorrowedNode = object
        raw: NodePtr
    Parser = object
        raw: ParserPtr

proc `=copy`(dest: var Node, source: Node) {.error.}
proc `=destroy`(x: var Node) = cmark_node_free(x.raw)
proc `=destroy`(x: var BorrowedNode) = discard

proc `=destroy`(x: var Parser) = cmark_parser_free(x.raw)

proc borrow(n: Node): BorrowedNode = BorrowedNode(raw: n.raw)

proc newParser(options: int64, extensions: seq[string]): Parser =
    let parser: ParserPtr = cmark_parser_new(options.cint)
    if parser == nil: raise newException(CatchableError, "failed to initialize parser")
    # load and enable desired syntax extensions
    # these are freed with the parser (probably)
    for ext in extensions:
        let e: cstring = ext
        let eptr = cmark_find_syntax_extension(e)
        if eptr == nil:
            cmark_parser_free(parser)
            raise newException(LibraryError, "failed to find extension " & ext)
        if cmark_parser_attach_syntax_extension(parser, eptr) == 0: 
            cmark_parser_free(parser)
            raise newException(CatchableError, "failed to attach extension " & ext)
    Parser(raw: parser)

proc parse(p: Parser, document: string): Node =
    let
        str: cstring = document
        length = len(document).csize_t
    cmark_parser_feed(p.raw, str, length)
    let ast = cmark_parser_finish(p.raw)
    if ast == nil: raise newException(CatchableError, "parsing failed - should not occur")
    Node(raw: ast)

proc nodeType(n: BorrowedNode): NodeType = cmark_node_get_type(n.raw)
proc nodeContent(n: BorrowedNode): string = $cmark_node_get_literal(n.raw)

proc newNode(ty: NodeType, content: string): Node =
    let raw = cmark_node_new(ty)
    if raw == nil: raise newException(CatchableError, "node creation failed")
    if cmark_node_set_literal(raw, content) != 1:
        cmark_node_free(raw)
        raise newException(CatchableError, "node content setting failed")
    Node(raw: raw)

proc parentNode(parentOf: BorrowedNode): BorrowedNode = BorrowedNode(raw: cmark_node_parent(parentOf.raw))
proc pushNodeAfter(after: BorrowedNode, node: sink Node) {.nodestroy.} = assert cmark_node_insert_before(after.raw, node.raw) == 1
proc unlinkNode(node: sink BorrowedNode): Node {.nodestroy.} =
    cmark_node_unlink(node.raw)
    Node(raw: node.raw)

proc render(ast: Node, options: int64, parser: Parser): string =
    let html: cstring = cmark_render_html(ast.raw, options.cint, cmark_parser_get_syntax_extensions(parser.raw))
    defer: free(html)
    result = $html

iterator cmarkTree(root: BorrowedNode): (EventType, BorrowedNode) {.inline.} =
    var iter = cmark_iter_new(root.raw)
    if iter == nil: raise newException(CatchableError, "iterator initialization failed")
    defer: cmark_iter_free(iter)
    while true:
        let ev = cmark_iter_next(iter)
        if ev == etDone: break
        let node: NodePtr = cmark_iter_get_node(iter)
        yield (ev, BorrowedNode(raw: node))

func wikilink(page, linkText: string): string =
    let vdom = buildHtml(a(href=pageToSlug(page), class="wikilink")): text linkText
    $vdom

autoInitializedThreadvar(wlRegex, Regex, re"\[\[([^:\]]+):?([^\]]+)?\]\]")
autoInitializedThreadvar(newlinesRegex, Regex, re"\n{2,}")

proc renderToHtml*(input: string): string =
    let wlRegex = wlRegex()
    let opt = CMARK_OPT_UNSAFE or CMARK_OPT_FOOTNOTES or CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE or CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES

    # initialize parser with the extensions in use, parse things
    let parser = newParser(opt, @["table", "strikethrough"])
    let doc = parse(parser, input)

    # iterate over AST using built-in cmark-gfm AST iteration thing
    for (evType, node) in cmarkTree(borrow(doc)):
        # if it is a text node
        if nodeType(node) == ntText:
            let ntext = nodeContent(node)
            # check for wikilinks in text node
            let matches = findAll(ntext, wlRegex)
            # if there are any, put in the appropriate HTML nodes
            if len(matches) > 0:
                var lastpos = 0
                # I think this does similar things to the snippet highlight code, perhaps it could be factored out somehow
                for match in matches:
                    let page = ntext[match.captures[0][0]] # I don't know why this doesn't use Option. Perhaps sometimes there are somehow > 1 ranges.
                    # if there is a separate linkText field, use this, otherwise just use the page
                    let linkText = 
                        if len(match.captures[1]) > 0: ntext[match.captures[1][0]]
                        else: page
                    let html = wikilink(page, linkText)
                    # push text before this onto the tree, as well as the HTML of the wikilink
                    pushNodeAfter(node, newNode(ntText, ntext[lastpos..<match.boundaries.a]))
                    pushNodeAfter(node, newNode(ntHtmlInline, html))
                    lastpos = match.boundaries.b + 1
                # push final text, if extant
                if lastpos != len(ntext): pushNodeAfter(node, newNode(ntText, ntext[lastpos..<len(ntext)]))
                # remove original text node
                discard unlinkNode(node)

    render(doc, opt, parser)

proc textContent(node: BorrowedNode): string =
    let newlinesRegex = newlinesRegex()
    for (evType, node) in cmarkTree(node):
        let ntype = nodeType(node)
        if ntype == ntText or ntype == ntCode:
            result &= nodeContent(node)
        elif int64(ntype) < CMARK_NODE_TYPE_INLINE and evType == etExit and ntype != ntItem:
            result &= "\n"
        elif ntype == ntSoftBreak:
            result &= " "
        elif ntype == ntLineBreak:
            result &= "\n"
    replace(strip(result), newlinesRegex, "\n")

proc findParagraphParent(node: BorrowedNode): BorrowedNode =
    result = node
    while nodeType(result) != ntParagraph: result = parentNode(result)

type 
    Link* = object
        target*, text*, context*: string
    ParsedPage* = object
        links*: seq[Link]
        #fullText*: string

# Generates context for a link given the surrounding string and its position in it
# Takes a given quantity of space-separated words from both sides
# If not enough exist on one side, takes more from the other
# TODO: treat a wikilink as one token
proc linkContext(str: string, startPos: int, endPos: int, lookaround: int): string =
    var earlierToks = if startPos > 0: splitWhitespace(str[0..<startPos]) else: @[]
    var linkText = str[startPos..endPos]
    var laterToks = if endPos < str.len: splitWhitespace(str[endPos + 1..^1]) else: @[]
    let bdlook = lookaround * 2
    result =
        # both are longer than necessary so take tokens symmetrically
        if earlierToks.len >= lookaround and laterToks.len >= lookaround: 
            earlierToks[^lookaround..^1].join(" ") & linkText & laterToks[0..<lookaround].join(" ")
        # later is shorter than wanted, take more from earlier
        elif earlierToks.len >= lookaround and laterToks.len < lookaround:
            earlierToks[max(earlierToks.len - bdlook + laterToks.len, 0)..^1].join(" ") & linkText & laterToks.join(" ")
        # mirrored version of previous case
        elif earlierToks.len < lookaround and laterToks.len >= lookaround: 
            earlierToks.join(" ") & linkText & laterToks[0..<min(bdlook - earlierToks.len, laterToks.len)].join(" ")
        # both too short, use all of both
        else: earlierToks.join(" ") & linkText & laterToks.join(" ")

    # TODO: optimize
    if not result.startsWith(earlierToks.join(" ")): result = "... " & result
    if not result.endsWith(laterToks.join(" ")): result = result & " ..."

proc parsePage*(input: string): ParsedPage =
    let wlRegex = wlRegex()
    let opt = CMARK_OPT_UNSAFE or CMARK_OPT_FOOTNOTES or CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE or CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES

    let parser = newParser(opt, @["table", "strikethrough"])
    let doc = parse(parser, input)

    var wikilinks: seq[Link] = @[]
    var seenPages: HashSet[string]

    for (evType, node) in cmarkTree(borrow(doc)):
        if nodeType(node) == ntText:
            let ntext = nodeContent(node)
            let matches = findAll(ntext, wlRegex)
            if len(matches) > 0:
                let paragraph = textContent(findParagraphParent(node))
                var matchEnd = 0
                for match in matches:
                    let page = ntext[match.captures[0][0]]
                    let linkText = 
                        if len(match.captures[1]) > 0: ntext[match.captures[1][0]]
                        else: page

                    let canonicalPage = slugToPage(page)
                    if not (canonicalPage in seenPages):
                        # matches in this text node will not necessarily line up with ones in the surrounding textual contentso look up the wikilink's source in the paragraph
                        # kind of hacky but should work in any scenario which isn't deliberately constructed pathologically, especially since it will only return stuff after the last link
                        let fullLink = ntext[match.boundaries]
                        let matchInParagraph = find(paragraph, fullLink, matchEnd)
                        matchEnd = matchInParagraph + fullLink.len - 1
                        let context = linkContext(paragraph, matchInParagraph, matchEnd, 12)

                        # add to wikilinks list, and deduplicate
                        wikilinks.add(Link(target: canonicalPage, text: linkText, context: context))
                        seenPages.incl(canonicalPage)

    ParsedPage(links: wikilinks) #fullText: textContent(borrow(doc)))