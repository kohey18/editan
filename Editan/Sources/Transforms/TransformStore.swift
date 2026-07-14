import AppKit
import SwiftUI

@MainActor
final class TransformStore: ObservableObject {
    enum Status: Equatable {
        case running
        case done(String)
        case failed(String)
    }

    struct Session {
        let template: TransformTemplate
        let original: String
        let targetRange: NSRange
        var status: Status = .running
    }

    @Published var templates: [TransformTemplate] = [] {
        didSet { if isLoaded { saveTemplates() } }
    }
    @Published var session: Session?
    @Published var showSheet = false
    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: "transformModel") }
    }

    private var isLoaded = false
    private let templatesURL: URL

    init() {
        model = UserDefaults.standard.string(forKey: "transformModel") ?? "sonnet"
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        templatesURL = appSupport.appendingPathComponent("Editan/templates.json")
        if let data = try? Data(contentsOf: templatesURL),
           let list = try? JSONDecoder().decode([TransformTemplate].self, from: data),
           !list.isEmpty {
            templates = list
        } else {
            templates = TransformTemplate.defaults
        }
        isLoaded = true
    }

    // MARK: - 変換実行

    func run(_ template: TransformTemplate) {
        if case .running = session?.status { return }
        guard let textView = EditorAccess.currentTextView() else { return }
        let whole = textView.string as NSString
        let selection = textView.selectedRange()
        let target = selection.length > 0 ? selection : NSRange(location: 0, length: whole.length)
        let original = whole.substring(with: target)
        guard !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        session = Session(template: template, original: original, targetRange: target)
        showSheet = true
        let model = self.model
        Task { [weak self] in
            do {
                let result = try await ClaudeCLI.transform(
                    instruction: template.prompt, input: original, model: model
                )
                self?.session?.status = .done(result.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                self?.session?.status = .failed(error.localizedDescription)
            }
        }
    }

    /// 変換結果で元のテキスト(選択範囲 or 全文)を置き換える(Undo 対応)。
    func applyReplacement() {
        guard let session, case .done(let result) = session.status,
              let textView = EditorAccess.currentTextView() else { return }
        let range = session.targetRange
        guard range.location + range.length <= (textView.string as NSString).length else { return }
        if textView.shouldChangeText(in: range, replacementString: result) {
            textView.textStorage?.replaceCharacters(in: range, with: result)
            textView.didChangeText()
        }
        dismiss()
    }

    func copyResult() {
        guard let session, case .done(let result) = session.status else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(result, forType: .string)
    }

    func dismiss() {
        showSheet = false
        session = nil
    }

    // MARK: - テンプレート管理

    func addTemplate() {
        templates.append(TransformTemplate(name: "新しいテンプレート", prompt: ""))
    }

    func removeTemplate(_ id: UUID) {
        templates.removeAll { $0.id == id }
    }

    private func saveTemplates() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(templates) {
            try? data.write(to: templatesURL, options: .atomic)
        }
    }
}
