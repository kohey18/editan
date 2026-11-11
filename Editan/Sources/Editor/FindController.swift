import AppKit
import SwiftUI

/// Chrome 風の検索バーの状態と、エディタ(PlainTextView)上のマッチ表示を管理する。
/// マッチの強調は TextKit 2 のレンダリング属性で行い、テキストストレージ(=ハイライトや Undo)には触らない。
@MainActor
final class FindController: ObservableObject {
    @Published var isVisible = false
    @Published var query = "" {
        didSet {
            guard query != oldValue else { return }
            refresh(anchor: caretLocation())
        }
    }
    @Published private(set) var matches: [NSRange] = []
    @Published private(set) var currentIndex: Int?
    /// 値が変わるたびに検索フィールドへフォーカス + 全選択する
    @Published private(set) var focusRequest = 0

    private static let options: NSString.CompareOptions = [.caseInsensitive, .widthInsensitive]
    private static let matchColor = NSColor.systemYellow.withAlphaComponent(0.45)
    private static let currentColor = NSColor.systemOrange.withAlphaComponent(0.85)

    var statusText: String {
        guard !query.isEmpty else { return "" }
        guard let currentIndex else { return "0 / 0" }
        return "\(currentIndex + 1) / \(matches.count)"
    }

    // MARK: - コマンド

    func show() {
        if let textView = EditorAccess.currentTextView(), !textView.hasMarkedText() {
            let selection = textView.selectedRange()
            if selection.length > 0, selection.length <= 200 {
                let selected = (textView.string as NSString).substring(with: selection)
                if !selected.contains("\n") { query = selected }
            }
        }
        isVisible = true
        focusRequest += 1
        refresh(anchor: caretLocation())
    }

    /// 選択範囲を検索文字列にする(⌘E)。バーは開かずに次/前検索で使える。
    func useSelection() {
        guard let textView = EditorAccess.currentTextView(), !textView.hasMarkedText() else { return }
        let selection = textView.selectedRange()
        guard selection.length > 0 else { return }
        query = (textView.string as NSString).substring(with: selection)
        if isVisible { refresh(anchor: selection.location) }
    }

    func next() { step(+1) }
    func previous() { step(-1) }

    func close() {
        guard isVisible else { return }
        isVisible = false
        guard let textView = EditorAccess.currentTextView() else { return }
        clearHighlights(in: textView)
        textView.window?.makeFirstResponder(textView)
        if let currentIndex, matches.indices.contains(currentIndex) {
            (textView as? PlainTextView)?.suppressNextSelectionBar = true
            textView.setSelectedRange(matches[currentIndex])
            textView.scrollRangeToVisible(matches[currentIndex])
        }
    }

    /// テキスト変更・バッファ切替後にマッチを数え直す。
    func textDidChange() {
        guard isVisible else { return }
        let anchor = currentIndex.flatMap { matches.indices.contains($0) ? matches[$0].location : nil }
        refresh(anchor: anchor ?? caretLocation(), reveal: false)
    }

    // MARK: - 内部

    private func step(_ delta: Int) {
        if !isVisible {
            guard !query.isEmpty else { show(); return }
            isVisible = true
            refresh(anchor: caretLocation(), reveal: false)
        }
        guard !matches.isEmpty else { return }
        let base = currentIndex ?? (delta > 0 ? -1 : 0)
        currentIndex = (base + delta + matches.count) % matches.count
        applyHighlights(reveal: true)
    }

    private func caretLocation() -> Int {
        EditorAccess.currentTextView()?.selectedRange().location ?? 0
    }

    private func refresh(anchor: Int, reveal: Bool = true) {
        guard let textView = EditorAccess.currentTextView() else {
            matches = []
            currentIndex = nil
            return
        }
        matches = Self.findAll(query, in: textView.string)
        if matches.isEmpty {
            currentIndex = nil
        } else {
            currentIndex = matches.firstIndex { $0.location >= anchor } ?? 0
        }
        applyHighlights(reveal: reveal)
    }

    private static func findAll(_ query: String, in text: String) -> [NSRange] {
        guard !query.isEmpty else { return [] }
        let ns = text as NSString
        var results: [NSRange] = []
        var searchRange = NSRange(location: 0, length: ns.length)
        while searchRange.length > 0 {
            let found = ns.range(of: query, options: options, range: searchRange)
            guard found.location != NSNotFound, found.length > 0 else { break }
            results.append(found)
            let next = found.location + found.length
            searchRange = NSRange(location: next, length: ns.length - next)
        }
        return results
    }

    private func applyHighlights(reveal: Bool) {
        guard let textView = EditorAccess.currentTextView() else { return }
        clearHighlights(in: textView)
        guard isVisible, let layout = textView.textLayoutManager,
              let content = layout.textContentManager else { return }
        for (index, range) in matches.enumerated() {
            guard let textRange = Self.textRange(range, in: content) else { continue }
            let color = index == currentIndex ? Self.currentColor : Self.matchColor
            layout.addRenderingAttribute(.backgroundColor, value: color, for: textRange)
        }
        textView.needsDisplay = true
        if reveal, let currentIndex, matches.indices.contains(currentIndex) {
            textView.scrollRangeToVisible(matches[currentIndex])
            textView.showFindIndicator(for: matches[currentIndex])
        }
    }

    private func clearHighlights(in textView: NSTextView) {
        guard let layout = textView.textLayoutManager,
              let content = layout.textContentManager else { return }
        layout.removeRenderingAttribute(.backgroundColor, for: content.documentRange)
        textView.needsDisplay = true
    }

    private static func textRange(_ range: NSRange, in content: NSTextContentManager) -> NSTextRange? {
        let documentStart = content.documentRange.location
        guard let start = content.location(documentStart, offsetBy: range.location),
              let end = content.location(start, offsetBy: range.length) else { return nil }
        return NSTextRange(location: start, end: end)
    }
}

/// エディタ右上に浮かぶ検索バー(Chrome 風)。
struct FindBar: View {
    @ObservedObject var find: FindController
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            TextField("検索", text: $find.query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .frame(width: 180)
                .focused($fieldFocused)
                .onSubmit { find.next() }
                .onKeyPress(.return, phases: .down) { press in
                    guard press.modifiers.contains(.shift) else { return .ignored }
                    find.previous()
                    return .handled
                }
                .onExitCommand { find.close() }
            Text(find.statusText)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(find.currentIndex == nil ? .tertiary : .secondary)
                .frame(minWidth: 44, alignment: .trailing)
            Divider().frame(height: 18)
            HStack(spacing: 2) {
                barButton("chevron.up", help: "前を検索 (⇧⌘G / ⇧↩)") { find.previous() }
                    .disabled(find.matches.isEmpty)
                barButton("chevron.down", help: "次を検索 (⌘G / ↩)") { find.next() }
                    .disabled(find.matches.isEmpty)
                barButton("xmark", help: "閉じる (esc)") { find.close() }
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        .onAppear { focusField() }
        .onChange(of: find.focusRequest) { focusField() }
    }

    private func barButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(help)
    }

    private func focusField() {
        fieldFocused = true
        // 再度 ⌘F したときも入力済みの文字列を全選択して打ち直せるようにする
        // (フォーカスがまだエディタにある場合に本文を全選択しないよう、フィールドエディタのときだけ)
        DispatchQueue.main.async {
            if let editor = NSApp.keyWindow?.firstResponder as? NSTextView, !(editor is PlainTextView) {
                editor.selectAll(nil)
            }
        }
    }
}
