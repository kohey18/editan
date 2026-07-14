import Foundation
import Markdown

/// Markdown を Slack のメッセージ入力欄に貼るためのテキスト(mrkdwn 風)に変換する。
/// - **bold** → *bold*、_italic_ はそのまま、~~strike~~ → ~strike~
/// - 見出し → 太字行、リンク → 「テキスト (URL)」
/// - リスト → 「• 」/「1. 」、ネストは4スペースインデント
enum SlackMarkdown {
    static func convert(_ markdown: String) -> String {
        let document = Document(parsing: markdown)
        return document.blockChildren
            .map { renderBlock($0, indent: 0) }
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - ブロック要素

    private static func renderBlock(_ markup: Markup, indent: Int) -> String {
        let pad = String(repeating: "    ", count: indent)
        switch markup {
        case let heading as Heading:
            return pad + "*" + renderInlineChildren(heading) + "*"
        case let paragraph as Paragraph:
            return renderInlineChildren(paragraph)
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { pad + $0 }
                .joined(separator: "\n")
        case let codeBlock as CodeBlock:
            var code = codeBlock.code
            if code.hasSuffix("\n") { code.removeLast() }
            return "```\n" + code + "\n```"
        case let quote as BlockQuote:
            return quote.blockChildren
                .map { renderBlock($0, indent: 0) }
                .joined(separator: "\n")
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { "> " + $0 }
                .joined(separator: "\n")
        case let list as UnorderedList:
            return list.listItems
                .map { renderItem($0, marker: "•", indent: indent) }
                .joined(separator: "\n")
        case let list as OrderedList:
            return list.listItems.enumerated()
                .map { offset, item in
                    renderItem(item, marker: "\(Int(list.startIndex) + offset).", indent: indent)
                }
                .joined(separator: "\n")
        case is ThematicBreak:
            return "──────────"
        case let html as HTMLBlock:
            return html.rawHTML.trimmingCharacters(in: .newlines)
        case let table as Table:
            var rows = [table.head.cells.map { renderInlineChildren($0) }.joined(separator: " | ")]
            for row in table.body.rows {
                rows.append(row.cells.map { renderInlineChildren($0) }.joined(separator: " | "))
            }
            return rows.joined(separator: "\n")
        default:
            return markup.children.map { renderBlock($0, indent: indent) }.joined(separator: "\n")
        }
    }

    private static func renderItem(_ item: ListItem, marker: String, indent: Int) -> String {
        let pad = String(repeating: "    ", count: indent)
        var checkbox = ""
        if let box = item.checkbox {
            checkbox = box == .checked ? "☑︎ " : "☐ "
        }
        var lines: [String] = []
        var usedMarker = false
        for child in item.blockChildren {
            if !usedMarker, let paragraph = child as? Paragraph {
                lines.append(pad + marker + " " + checkbox + renderInlineChildren(paragraph))
                usedMarker = true
            } else {
                lines.append(renderBlock(child, indent: indent + 1))
            }
        }
        if lines.isEmpty { lines.append(pad + marker + " " + checkbox) }
        return lines.joined(separator: "\n")
    }

    // MARK: - インライン要素

    private static func renderInlineChildren(_ markup: Markup) -> String {
        markup.children.map { renderInline($0) }.joined()
    }

    private static func renderInline(_ markup: Markup) -> String {
        switch markup {
        case let text as Markdown.Text:
            return text.string
        case let code as InlineCode:
            return "`\(code.code)`"
        case let strong as Strong:
            return "*" + renderInlineChildren(strong) + "*"
        case let emphasis as Emphasis:
            return "_" + renderInlineChildren(emphasis) + "_"
        case let strike as Strikethrough:
            return "~" + renderInlineChildren(strike) + "~"
        case let link as Link:
            let text = renderInlineChildren(link)
            guard let destination = link.destination, !destination.isEmpty else { return text }
            return text.isEmpty || text == destination ? destination : "\(text) (\(destination))"
        case let image as Markdown.Image:
            return image.source ?? ""
        case is SoftBreak, is LineBreak:
            return "\n"
        case let html as InlineHTML:
            return html.rawHTML
        default:
            return renderInlineChildren(markup)
        }
    }
}
