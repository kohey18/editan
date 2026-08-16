import Foundation
import Markdown

/// swift-markdown 標準の HTMLFormatter はテキスト・コード・属性を一切エスケープせず、
/// 生 HTML(HTMLBlock / InlineHTML)も素通しするため、信頼できない .md を開くと
/// プレビューの WKWebView で任意の JS が実行できてしまう。
/// この安全版はすべてのテキスト・属性をエスケープし、生 HTML はエスケープして
/// そのまま文字として表示する。リンク・画像のスキームも許可リストで絞る。
struct SafeHTMLFormatter: MarkupWalker {
    private(set) var result = ""
    private var tableColumnAlignments: [Table.ColumnAlignment?]?
    private var currentTableColumn = 0
    private var inTableHead = false

    static func format(_ document: Document) -> String {
        var formatter = SafeHTMLFormatter()
        formatter.visit(document)
        return formatter.result
    }

    // MARK: - エスケープ / URL 検証

    private static func escaped(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func escapedAttribute(_ string: String) -> String {
        escaped(string).replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// javascript: 等の危険なスキームを落とす。ブラウザはスキーム中の制御文字を
    /// 無視して解釈するため、制御文字・空白を除去してから判定する
    private static func sanitizedDestination(
        _ destination: String?, allowedSchemes: Set<String>
    ) -> String? {
        guard let destination, !destination.isEmpty else { return nil }
        let cleaned = String(String.UnicodeScalarView(
            destination.unicodeScalars.filter { $0.value > 0x20 }
        ))
        guard !cleaned.isEmpty else { return nil }
        if let colon = cleaned.firstIndex(of: ":"),
           !cleaned[..<colon].contains(where: { "/?#".contains($0) }) {
            let scheme = cleaned[..<colon].lowercased()
            guard allowedSchemes.contains(scheme) else { return nil }
        }
        return cleaned
    }

    private static let linkSchemes: Set<String> = ["http", "https", "mailto"]
    private static let imageSchemes: Set<String> = ["http", "https", "data"]

    // MARK: - ブロック要素

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result += "<blockquote>\n"
        descendInto(blockQuote)
        result += "</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let languageAttr: String
        if let language = codeBlock.language, !language.isEmpty {
            languageAttr = " class=\"language-\(Self.escapedAttribute(language))\""
        } else {
            languageAttr = ""
        }
        result += "<pre><code\(languageAttr)>\(Self.escaped(codeBlock.code))</code></pre>\n"
    }

    mutating func visitHeading(_ heading: Heading) {
        result += "<h\(heading.level)>"
        descendInto(heading)
        result += "</h\(heading.level)>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "<hr />\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        let literal = html.rawHTML.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !literal.isEmpty else { return }
        result += "<p>\(Self.escaped(literal))</p>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) {
        result += "<li>"
        if let checkbox = listItem.checkbox {
            result += "<input type=\"checkbox\" disabled=\"\""
            if checkbox == .checked {
                result += " checked=\"\""
            }
            result += " /> "
        }
        descendInto(listItem)
        result += "</li>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        let start = orderedList.startIndex != 1 ? " start=\"\(orderedList.startIndex)\"" : ""
        result += "<ol\(start)>\n"
        descendInto(orderedList)
        result += "</ol>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        result += "<ul>\n"
        descendInto(unorderedList)
        result += "</ul>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        result += "<p>"
        descendInto(paragraph)
        result += "</p>\n"
    }

    // MARK: - テーブル

    mutating func visitTable(_ table: Table) {
        result += "<table>\n"
        tableColumnAlignments = table.columnAlignments
        descendInto(table)
        tableColumnAlignments = nil
        result += "</table>\n"
    }

    mutating func visitTableHead(_ tableHead: Table.Head) {
        result += "<thead>\n<tr>\n"
        inTableHead = true
        currentTableColumn = 0
        descendInto(tableHead)
        inTableHead = false
        result += "</tr>\n</thead>\n"
    }

    mutating func visitTableBody(_ tableBody: Table.Body) {
        if !tableBody.isEmpty {
            result += "<tbody>\n"
            descendInto(tableBody)
            result += "</tbody>\n"
        }
    }

    mutating func visitTableRow(_ tableRow: Table.Row) {
        result += "<tr>\n"
        currentTableColumn = 0
        descendInto(tableRow)
        result += "</tr>\n"
    }

    mutating func visitTableCell(_ tableCell: Table.Cell) {
        guard let alignments = tableColumnAlignments, currentTableColumn < alignments.count else { return }
        guard tableCell.colspan > 0 && tableCell.rowspan > 0 else { return }

        let element = inTableHead ? "th" : "td"
        result += "<\(element)"
        if let alignment = alignments[currentTableColumn] {
            result += " align=\"\(alignment)\""
        }
        currentTableColumn += 1
        if tableCell.rowspan > 1 { result += " rowspan=\"\(tableCell.rowspan)\"" }
        if tableCell.colspan > 1 { result += " colspan=\"\(tableCell.colspan)\"" }
        result += ">"
        descendInto(tableCell)
        result += "</\(element)>\n"
    }

    // MARK: - インライン要素

    private mutating func printInline(tag: String, _ content: Markup) {
        result += "<\(tag)>"
        descendInto(content)
        result += "</\(tag)>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += "<code>\(Self.escaped(inlineCode.code))</code>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        printInline(tag: "em", emphasis)
    }

    mutating func visitStrong(_ strong: Strong) {
        printInline(tag: "strong", strong)
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        printInline(tag: "del", strikethrough)
    }

    mutating func visitImage(_ image: Image) {
        result += "<img"
        if let source = Self.sanitizedDestination(image.source, allowedSchemes: Self.imageSchemes) {
            result += " src=\"\(Self.escapedAttribute(source))\""
        }
        if let title = image.title, !title.isEmpty {
            result += " title=\"\(Self.escapedAttribute(title))\""
        }
        result += " />"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        result += Self.escaped(inlineHTML.rawHTML)
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "<br />\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += "\n"
    }

    mutating func visitLink(_ link: Link) {
        result += "<a"
        if let destination = Self.sanitizedDestination(link.destination, allowedSchemes: Self.linkSchemes) {
            result += " href=\"\(Self.escapedAttribute(destination))\""
        }
        result += ">"
        descendInto(link)
        result += "</a>"
    }

    mutating func visitText(_ text: Text) {
        result += Self.escaped(text.string)
    }

    mutating func visitSymbolLink(_ symbolLink: SymbolLink) {
        if let destination = symbolLink.destination {
            result += "<code>\(Self.escaped(destination))</code>"
        }
    }
}
