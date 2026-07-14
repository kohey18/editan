import Foundation
import Markdown

/// Markdown を Notion API のブロック JSON に変換する。
enum NotionBlocks {
    static func convert(_ markdown: String) -> [[String: Any]] {
        let document = Document(parsing: markdown)
        return document.blockChildren.flatMap { blocks(from: $0) }
    }

    // MARK: - ブロック要素

    private static func blocks(from markup: Markup) -> [[String: Any]] {
        switch markup {
        case let heading as Heading:
            let type = "heading_\(min(heading.level, 3))"
            return [block(type, ["rich_text": richText(heading)])]
        case let paragraph as Paragraph:
            return [block("paragraph", ["rich_text": richText(paragraph)])]
        case let codeBlock as CodeBlock:
            var code = codeBlock.code
            if code.hasSuffix("\n") { code.removeLast() }
            return [block("code", [
                "rich_text": [textObject(code)],
                "language": notionLanguage(codeBlock.language),
            ])]
        case let quote as BlockQuote:
            let inner = quote.blockChildren.flatMap { child -> [[String: Any]] in
                if let paragraph = child as? Paragraph { return richText(paragraph) }
                return [textObject(child.format())]
            }
            return [block("quote", ["rich_text": inner])]
        case let list as UnorderedList:
            return list.listItems.map { listItemBlock($0, ordered: false) }
        case let list as OrderedList:
            return list.listItems.map { listItemBlock($0, ordered: true) }
        case is ThematicBreak:
            return [block("divider", [:])]
        case let table as Table:
            var rows = [table.head.cells.map { plainText($0) }.joined(separator: " | ")]
            for row in table.body.rows {
                rows.append(row.cells.map { plainText($0) }.joined(separator: " | "))
            }
            return rows.map { block("paragraph", ["rich_text": [textObject($0)]]) }
        default:
            let text = markup.format().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return [] }
            return [block("paragraph", ["rich_text": [textObject(text)]])]
        }
    }

    private static func listItemBlock(_ item: ListItem, ordered: Bool) -> [String: Any] {
        let type: String
        var content: [String: Any] = [:]
        if let checkbox = item.checkbox {
            type = "to_do"
            content["checked"] = checkbox == .checked
        } else {
            type = ordered ? "numbered_list_item" : "bulleted_list_item"
        }

        var inline: [[String: Any]] = []
        var children: [[String: Any]] = []
        for child in item.blockChildren {
            if inline.isEmpty, let paragraph = child as? Paragraph {
                inline = richText(paragraph)
            } else {
                children.append(contentsOf: blocks(from: child))
            }
        }
        content["rich_text"] = inline
        if !children.isEmpty { content["children"] = children }
        return block(type, content)
    }

    private static func block(_ type: String, _ content: [String: Any]) -> [String: Any] {
        ["object": "block", "type": type, type: content]
    }

    // MARK: - インライン要素

    private static func richText(_ container: Markup) -> [[String: Any]] {
        var out: [[String: Any]] = []

        func walk(_ markup: Markup, bold: Bool, italic: Bool, strike: Bool, code: Bool, link: String?) {
            switch markup {
            case let text as Markdown.Text:
                out.append(textObject(text.string, bold: bold, italic: italic, strike: strike, code: code, link: link))
            case let inlineCode as InlineCode:
                out.append(textObject(inlineCode.code, bold: bold, italic: italic, strike: strike, code: true, link: link))
            case let strong as Strong:
                strong.children.forEach { walk($0, bold: true, italic: italic, strike: strike, code: code, link: link) }
            case let emphasis as Emphasis:
                emphasis.children.forEach { walk($0, bold: bold, italic: true, strike: strike, code: code, link: link) }
            case let strikethrough as Strikethrough:
                strikethrough.children.forEach { walk($0, bold: bold, italic: italic, strike: true, code: code, link: link) }
            case let linkNode as Markdown.Link:
                linkNode.children.forEach { walk($0, bold: bold, italic: italic, strike: strike, code: code, link: linkNode.destination) }
            case is SoftBreak, is LineBreak:
                out.append(textObject("\n", bold: bold, italic: italic, strike: strike, code: code, link: link))
            default:
                markup.children.forEach { walk($0, bold: bold, italic: italic, strike: strike, code: code, link: link) }
            }
        }

        container.children.forEach { walk($0, bold: false, italic: false, strike: false, code: false, link: nil) }
        return out
    }

    private static func textObject(
        _ string: String,
        bold: Bool = false, italic: Bool = false, strike: Bool = false, code: Bool = false,
        link: String? = nil
    ) -> [String: Any] {
        var text: [String: Any] = ["content": String(string.prefix(2000))]
        if let link, URL(string: link) != nil {
            text["link"] = ["url": link]
        }
        var object: [String: Any] = ["type": "text", "text": text]
        var annotations: [String: Any] = [:]
        if bold { annotations["bold"] = true }
        if italic { annotations["italic"] = true }
        if strike { annotations["strikethrough"] = true }
        if code { annotations["code"] = true }
        if !annotations.isEmpty { object["annotations"] = annotations }
        return object
    }

    private static func plainText(_ container: Markup) -> String {
        richText(container).compactMap {
            (($0["text"] as? [String: Any])?["content"] as? String)
        }.joined()
    }

    private static let knownLanguages: Set<String> = [
        "bash", "c", "c++", "c#", "css", "go", "graphql", "html", "java", "javascript",
        "json", "kotlin", "markdown", "objective-c", "php", "python", "ruby", "rust",
        "scala", "shell", "sql", "swift", "typescript", "yaml",
    ]

    private static func notionLanguage(_ language: String?) -> String {
        guard let language = language?.lowercased(), !language.isEmpty else { return "plain text" }
        switch language {
        case "js": return "javascript"
        case "ts": return "typescript"
        case "sh", "zsh": return "shell"
        case "py": return "python"
        default: return knownLanguages.contains(language) ? language : "plain text"
        }
    }
}
