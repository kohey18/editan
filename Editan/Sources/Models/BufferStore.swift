import AppKit
import Markdown
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class BufferStore: ObservableObject {
    @Published var buffers: [Buffer] = []
    @Published var selectedID: UUID?
    @Published var showPreview = true

    private let rootDir: URL
    private let scratchDir: URL
    private let indexURL: URL
    private var dirtyScratchIDs: Set<UUID> = []
    private var saveTask: Task<Void, Never>?

    private struct IndexEntry: Codable {
        var id: UUID
        var filePath: String?
        var createdAt: Date
    }

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        rootDir = appSupport.appendingPathComponent("Editan", isDirectory: true)
        scratchDir = rootDir.appendingPathComponent("Buffers", isDirectory: true)
        indexURL = rootDir.appendingPathComponent("index.json")
        try? FileManager.default.createDirectory(at: scratchDir, withIntermediateDirectories: true)

        load()
        if buffers.isEmpty { newBuffer() }
        selectedID = buffers.first?.id

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { [weak self] in self?.flushNow() }
        }
    }

    var selectedIndex: Int? {
        buffers.firstIndex { $0.id == selectedID }
    }

    var selectedBuffer: Buffer? {
        selectedIndex.map { buffers[$0] }
    }

    // MARK: - 編集

    func updateContent(id: UUID, _ newContent: String) {
        guard let idx = buffers.firstIndex(where: { $0.id == id }),
              buffers[idx].content != newContent else { return }
        buffers[idx].content = newContent
        if buffers[idx].isScratch {
            dirtyScratchIDs.insert(id)
            scheduleFlush()
        } else {
            buffers[idx].hasUnsavedChanges = true
        }
    }

    // MARK: - バッファ操作

    func newBuffer() {
        let buffer = Buffer(id: UUID(), content: "", fileURL: nil, createdAt: Date())
        buffers.append(buffer)
        selectedID = buffer.id
        try? "".write(to: scratchFileURL(buffer.id), atomically: true, encoding: .utf8)
        saveIndex()
    }

    func deleteBuffer(_ id: UUID) {
        guard let idx = buffers.firstIndex(where: { $0.id == id }) else { return }
        let buffer = buffers[idx]

        let needsConfirm = (buffer.isScratch && !buffer.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            || (!buffer.isScratch && buffer.hasUnsavedChanges)
        if needsConfirm {
            let alert = NSAlert()
            alert.messageText = "「\(buffer.title)」を削除しますか?"
            alert.informativeText = buffer.isScratch
                ? "スクラッチバッファの内容は失われます。この操作は取り消せません。"
                : "未保存の変更は失われます(ファイル自体は削除されません)。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "削除")
            alert.addButton(withTitle: "キャンセル")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }

        if buffer.isScratch {
            try? FileManager.default.removeItem(at: scratchFileURL(id))
            dirtyScratchIDs.remove(id)
        }
        buffers.remove(at: idx)

        if buffers.isEmpty {
            newBuffer()
        } else if selectedID == id {
            selectedID = buffers[min(idx, buffers.count - 1)].id
        }
        saveIndex()
    }

    // MARK: - ファイル入出力

    func openDocument() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        for url in panel.urls { openFile(at: url) }
    }

    func openFile(at url: URL) {
        if let existing = buffers.first(where: { $0.fileURL == url }) {
            selectedID = existing.id
            return
        }
        guard let content = readText(at: url) else {
            let alert = NSAlert()
            alert.messageText = "ファイルを開けませんでした"
            alert.informativeText = "「\(url.lastPathComponent)」はテキストとして読み込めません。"
            alert.runModal()
            return
        }
        let buffer = Buffer(id: UUID(), content: content, fileURL: url, createdAt: Date())
        buffers.append(buffer)
        selectedID = buffer.id
        saveIndex()
    }

    func saveSelected() {
        guard let idx = selectedIndex else { return }
        guard let url = buffers[idx].fileURL else {
            saveSelectedAs()
            return
        }
        try? buffers[idx].content.write(to: url, atomically: true, encoding: .utf8)
        buffers[idx].hasUnsavedChanges = false
    }

    func saveSelectedAs() {
        guard let idx = selectedIndex else { return }
        let buffer = buffers[idx]
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.allowsOtherFileTypes = true
        panel.nameFieldStringValue = buffer.isScratch ? "\(buffer.title).md" : buffer.title
        guard panel.runModal() == .OK, let url = panel.url else { return }

        try? buffer.content.write(to: url, atomically: true, encoding: .utf8)
        if buffer.isScratch {
            try? FileManager.default.removeItem(at: scratchFileURL(buffer.id))
            dirtyScratchIDs.remove(buffer.id)
        }
        buffers[idx].fileURL = url
        buffers[idx].hasUnsavedChanges = false
        saveIndex()
    }

    // MARK: - 変換・コピー

    /// 変換系コマンドの対象テキスト。エディタに選択範囲があればそれ、なければ全文。
    private func sourceText() -> String? {
        if let textView = EditorAccess.currentTextView() {
            let selection = textView.selectedRange()
            if selection.length > 0 {
                return (textView.string as NSString).substring(with: selection)
            }
            return textView.string
        }
        return selectedBuffer?.content
    }

    func copyForSlack() {
        guard let text = sourceText() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(SlackMarkdown.convert(text), forType: .string)
    }

    func copyAsRichText() {
        guard let text = sourceText() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(MarkdownRenderer.body(from: text), forType: .html)
        pasteboard.setString(text, forType: .string)
    }

    func formatMarkdown() {
        guard let idx = selectedIndex else { return }
        let source = buffers[idx].content
        var formatted = Document(parsing: source).format()
        if !formatted.isEmpty, !formatted.hasSuffix("\n"), source.hasSuffix("\n") {
            formatted += "\n"
        }
        guard formatted != source else { return }
        if let textView = EditorAccess.currentTextView() {
            // Undo に載せるため NSTextView 経由で置換(textDidChange で store に反映される)
            EditorAccess.replaceAllText(with: formatted, in: textView)
        } else {
            updateContent(id: buffers[idx].id, formatted)
        }
    }

    // MARK: - 永続化

    func flushNow() {
        saveTask?.cancel()
        saveTask = nil
        for id in dirtyScratchIDs {
            guard let buffer = buffers.first(where: { $0.id == id }), buffer.isScratch else { continue }
            try? buffer.content.write(to: scratchFileURL(id), atomically: true, encoding: .utf8)
        }
        dirtyScratchIDs.removeAll()
        saveIndex()
    }

    private func scheduleFlush() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.flushNow()
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let entries = try? JSONDecoder().decode([IndexEntry].self, from: data) else { return }
        for entry in entries {
            if let path = entry.filePath {
                let url = URL(fileURLWithPath: path)
                guard let content = readText(at: url) else { continue }
                buffers.append(Buffer(id: entry.id, content: content, fileURL: url, createdAt: entry.createdAt))
            } else {
                let content = (try? String(contentsOf: scratchFileURL(entry.id), encoding: .utf8)) ?? ""
                buffers.append(Buffer(id: entry.id, content: content, fileURL: nil, createdAt: entry.createdAt))
            }
        }
    }

    private func saveIndex() {
        let entries = buffers.map { IndexEntry(id: $0.id, filePath: $0.fileURL?.path, createdAt: $0.createdAt) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(entries) {
            try? data.write(to: indexURL, options: .atomic)
        }
    }

    private func scratchFileURL(_ id: UUID) -> URL {
        scratchDir.appendingPathComponent("\(id.uuidString).md")
    }

    private func readText(at url: URL) -> String? {
        if let s = try? String(contentsOf: url, encoding: .utf8) { return s }
        if let s = try? String(contentsOf: url, encoding: .shiftJIS) { return s }
        return nil
    }
}
