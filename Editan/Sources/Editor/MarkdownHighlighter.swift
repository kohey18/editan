import AppKit
import Markdown

/// swift-markdown の SourceLocation(行 + UTF-8 バイト列)を NSRange(UTF-16)に変換する。
final class SourceMap {
    private let lines: [Substring]
    private let lineStarts: [Int]

    init(_ string: String) {
        let parts = string.split(separator: "\n", omittingEmptySubsequences: false)
        var starts: [Int] = []
        starts.reserveCapacity(parts.count)
        var position = 0
        for part in parts {
            starts.append(position)
            position += part.utf16.count + 1
        }
        lines = parts
        lineStarts = starts
    }

    func nsRange(_ range: SourceRange) -> NSRange? {
        guard let start = utf16Offset(range.lowerBound),
              let end = utf16Offset(range.upperBound),
              end >= start else { return nil }
        return NSRange(location: start, length: end - start)
    }

    private func utf16Offset(_ location: SourceLocation) -> Int? {
        let lineIndex = location.line - 1
        guard lineIndex >= 0, lineIndex < lines.count else { return nil }
        let line = lines[lineIndex]
        let utf8 = line.utf8
        guard let index = utf8.index(utf8.startIndex, offsetBy: location.column - 1, limitedBy: utf8.endIndex) else {
            return lineStarts[lineIndex] + line.utf16.count
        }
        return lineStarts[lineIndex] + line.utf16.distance(from: line.utf16.startIndex, to: index)
    }
}

@MainActor
enum MarkdownHighlighter {
    static let baseFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    static let boldFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
    static let baseAttributes: [NSAttributedString.Key: Any] = [
        .font: baseFont,
        .foregroundColor: NSColor.textColor,
    ]

    static func highlight(_ textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let string = textView.string
        let full = NSRange(location: 0, length: (string as NSString).length)
        guard full.length > 0 else { return }

        let document = Document(parsing: string)
        let map = SourceMap(string)

        storage.beginEditing()
        storage.setAttributes(baseAttributes, range: full)
        var styler = Styler(storage: storage, map: map, limit: full.length)
        styler.visit(document)
        storage.endEditing()
    }
}

private struct Styler: MarkupWalker {
    let storage: NSTextStorage
    let map: SourceMap
    let limit: Int

    private static let codeBackground = NSColor.gray.withAlphaComponent(0.15)

    private func nsRange(of markup: Markup) -> NSRange? {
        guard let sourceRange = markup.range, let r = map.nsRange(sourceRange) else { return nil }
        let location = min(r.location, limit)
        let length = min(r.length, limit - location)
        return length > 0 ? NSRange(location: location, length: length) : nil
    }

    private func add(_ attributes: [NSAttributedString.Key: Any], to markup: Markup) {
        guard let range = nsRange(of: markup) else { return }
        storage.addAttributes(attributes, range: range)
    }

    mutating func visitHeading(_ heading: Heading) {
        add([.font: MarkdownHighlighter.boldFont, .foregroundColor: NSColor.systemBlue], to: heading)
        descendInto(heading)
    }

    mutating func visitStrong(_ strong: Strong) {
        add([.font: MarkdownHighlighter.boldFont], to: strong)
        descendInto(strong)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        add([.obliqueness: 0.15], to: emphasis)
        descendInto(emphasis)
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        add([
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: NSColor.secondaryLabelColor,
        ], to: strikethrough)
        descendInto(strikethrough)
    }

    func visitInlineCode(_ inlineCode: InlineCode) {
        add([.foregroundColor: NSColor.systemOrange, .backgroundColor: Self.codeBackground], to: inlineCode)
    }

    func visitCodeBlock(_ codeBlock: CodeBlock) {
        add([.foregroundColor: NSColor.systemOrange, .backgroundColor: Self.codeBackground], to: codeBlock)
    }

    mutating func visitLink(_ link: Link) {
        add([.foregroundColor: NSColor.linkColor], to: link)
        descendInto(link)
    }

    mutating func visitImage(_ image: Image) {
        add([.foregroundColor: NSColor.linkColor], to: image)
        descendInto(image)
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        add([.foregroundColor: NSColor.secondaryLabelColor], to: blockQuote)
        descendInto(blockQuote)
    }

    func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        add([.foregroundColor: NSColor.secondaryLabelColor], to: thematicBreak)
    }

    mutating func visitListItem(_ listItem: ListItem) {
        // マーカー部分(項目先頭〜最初の子要素の手前)だけ色付け
        if let itemRange = nsRange(of: listItem),
           let firstChild = listItem.child(at: 0),
           let childRange = nsRange(of: firstChild),
           childRange.location > itemRange.location {
            let markerRange = NSRange(location: itemRange.location, length: childRange.location - itemRange.location)
            storage.addAttributes([.foregroundColor: NSColor.systemPink], range: markerRange)
        }
        descendInto(listItem)
    }
}
