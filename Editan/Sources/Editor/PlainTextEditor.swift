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
