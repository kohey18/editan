import AppKit
import SwiftUI

/// コピーが常にプレーンテキストであることを保証する NSTextView。
final class PlainTextView: NSTextView {
    override func copy(_ sender: Any?) {
        copySelectionAsPlainText()
    }

    override func cut(_ sender: Any?) {
        guard copySelectionAsPlainText() else { return }
        delete(sender)
    }

    // MARK: - リスト・引用の継続入力

    private static let listPattern = try! NSRegularExpression(
        pattern: "^([ \\t]*)([-*+]|[0-9]+[.)])([ \\t]+)(\\[[ xX]\\][ \\t]+)?(.*)$"
    )
    private static let quotePattern = try! NSRegularExpression(
        pattern: "^([ \\t]*(?:>[ \\t]?)+)(.*)$"
    )

    override func insertNewline(_ sender: Any?) {
        guard !hasMarkedText(), selectedRange().length == 0 else {
            super.insertNewline(sender)
            return
        }
        let ns = string as NSString
        let caret = selectedRange().location
        let lineRange = ns.lineRange(for: NSRange(location: caret, length: 0))
        var line = ns.substring(with: lineRange)
        if line.hasSuffix("\n") { line.removeLast() }
        let lineNS = line as NSString
        let fullLine = NSRange(location: 0, length: lineNS.length)
        let caretInLine = caret - lineRange.location

        // リスト項目: インデント + マーカーを引き継ぐ。空項目ならマーカーを消して抜ける
        if let match = Self.listPattern.firstMatch(in: line, range: fullLine) {
            let contentRange = match.range(at: 5)
            let prefixLength = contentRange.location
            if caretInLine >= prefixLength {
                let content = lineNS.substring(with: contentRange)
                if content.trimmingCharacters(in: .whitespaces).isEmpty {
                    insertText("", replacementRange: NSRange(location: lineRange.location, length: caretInLine))
                    return
                }
                let indent = lineNS.substring(with: match.range(at: 1))
                let marker = lineNS.substring(with: match.range(at: 2))
                let spacing = lineNS.substring(with: match.range(at: 3))
                var nextMarker = marker
                if let number = Int(marker.dropLast()) {
                    nextMarker = "\(number + 1)\(marker.suffix(1))"
                }
                let checkbox = match.range(at: 4).location != NSNotFound ? "[ ] " : ""
                insertText("\n" + indent + nextMarker + spacing + checkbox, replacementRange: selectedRange())
                return
            }
        } else if let match = Self.quotePattern.firstMatch(in: line, range: fullLine) {
            // 引用: "> " を引き継ぐ。空の引用行なら抜ける
            let prefixLength = match.range(at: 1).length
            if caretInLine >= prefixLength {
                let content = lineNS.substring(with: match.range(at: 2))
                if content.trimmingCharacters(in: .whitespaces).isEmpty {
                    insertText("", replacementRange: NSRange(location: lineRange.location, length: caretInLine))
                    return
                }
                insertText("\n" + lineNS.substring(with: match.range(at: 1)), replacementRange: selectedRange())
                return
            }
        } else {
            // 通常行: 行頭の空白インデントを維持
            var wsLength = 0
            while wsLength < min(caretInLine, lineNS.length) {
                let c = lineNS.character(at: wsLength)
                if c == 0x20 || c == 0x09 { wsLength += 1 } else { break }
            }
            if wsLength > 0 {
                insertText("\n" + lineNS.substring(to: wsLength), replacementRange: selectedRange())
                return
            }
        }
        super.insertNewline(sender)
    }

    @discardableResult
    private func copySelectionAsPlainText() -> Bool {
        let whole = string as NSString
        let parts = selectedRanges.compactMap { value -> String? in
            let range = value.rangeValue
            return range.length > 0 ? whole.substring(with: range) : nil
        }
        guard !parts.isEmpty else { return false }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(parts.joined(separator: "\n"), forType: .string)
        return true
    }
}

struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String
    var highlightsMarkdown = true

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PlainTextView(frame: .zero)
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.font = MarkdownHighlighter.baseFont
        textView.typingAttributes = MarkdownHighlighter.baseAttributes
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.textContainerInset = NSSize(width: 8, height: 12)
        textView.delegate = context.coordinator

        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.string = text
        if highlightsMarkdown {
            MarkdownHighlighter.highlight(textView)
        }

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else { return }
        // IME 変換中に外から string を差し替えると変換が壊れるためガード
        if textView.string != text, !textView.hasMarkedText() {
            let selection = textView.selectedRange()
            textView.string = text
            let location = min(selection.location, (text as NSString).length)
            textView.setSelectedRange(NSRange(location: location, length: 0))
            if highlightsMarkdown {
                MarkdownHighlighter.highlight(textView)
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        private var pendingHighlight: DispatchWorkItem?

        init(_ parent: PlainTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            scheduleHighlight(textView)
        }

        private func scheduleHighlight(_ textView: NSTextView) {
            guard parent.highlightsMarkdown else { return }
            pendingHighlight?.cancel()
            let work = DispatchWorkItem { [weak textView] in
                MainActor.assumeIsolated {
                    // IME 変換中に属性を触ると変換が壊れるため、確定後の変更イベントに任せる
                    guard let textView, !textView.hasMarkedText() else { return }
                    MarkdownHighlighter.highlight(textView)
                }
            }
            pendingHighlight = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
        }
    }
}
