import AppKit
import SwiftUI

@MainActor
final class FormatStore: ObservableObject {
    @Published var templates: [FormatTemplate] = [] {
        didSet { if isLoaded { save() } }
    }

    private var isLoaded = false
    private let templatesURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        templatesURL = appSupport.appendingPathComponent("Editan/formats.json")
        if let data = try? Data(contentsOf: templatesURL),
           let list = try? JSONDecoder().decode([FormatTemplate].self, from: data),
           !list.isEmpty {
            templates = list
        } else {
            templates = FormatTemplate.defaults
        }
        isLoaded = true
    }

    // MARK: - 挿入

    /// カーソル位置(選択があれば置換)にテンプレートを挿入し、{{cursor}} の位置へキャレットを移す。
    func insert(_ template: FormatTemplate) {
        guard let textView = EditorAccess.currentTextView(), !textView.hasMarkedText() else { return }

        var text = Self.expandPlaceholders(template.content) as NSString
        var caretOffset = text.length
        let marker = text.range(of: "{{cursor}}")
        if marker.location != NSNotFound {
            text = text.replacingCharacters(in: marker, with: "") as NSString
            caretOffset = marker.location
        }

        let selection = textView.selectedRange()
        guard textView.shouldChangeText(in: selection, replacementString: text as String) else { return }
        textView.textStorage?.replaceCharacters(in: selection, with: text as String)
        textView.didChangeText()

        let caret = NSRange(location: selection.location + caretOffset, length: 0)
        textView.setSelectedRange(caret)
        textView.scrollRangeToVisible(caret)
        textView.window?.makeFirstResponder(textView)
    }

    /// {{date}} / {{time}} / {{weekday}} を現在日時で展開する({{cursor}} は insert 側で処理)。
    static func expandPlaceholders(_ content: String, now: Date = Date()) -> String {
        func formatted(_ format: String) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = format
            return formatter.string(from: now)
        }
        return content
            .replacingOccurrences(of: "{{date}}", with: formatted("yyyy-MM-dd"))
            .replacingOccurrences(of: "{{time}}", with: formatted("HH:mm"))
            .replacingOccurrences(of: "{{weekday}}", with: formatted("E"))
    }

    // MARK: - テンプレート管理

    func addTemplate() {
        templates.append(FormatTemplate(name: "新しいフォーマット", content: ""))
    }

    func removeTemplate(_ id: UUID) {
        templates.removeAll { $0.id == id }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(templates) {
            try? data.write(to: templatesURL, options: .atomic)
        }
    }
}
