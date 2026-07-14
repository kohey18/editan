import Foundation

struct Buffer: Identifiable, Equatable {
    let id: UUID
    var content: String
    var fileURL: URL?
    var hasUnsavedChanges = false
    var createdAt: Date

    var isScratch: Bool { fileURL == nil }

    /// スクラッチはプレビュー可能。ファイルは拡張子で判定。
    var isMarkdown: Bool {
        guard let fileURL else { return true }
        return ["md", "markdown", "mdown", "txt"].contains(fileURL.pathExtension.lowercased())
    }

    /// サイドバー表示名。スクラッチは先頭の非空行から導出。
    var title: String {
        if let fileURL { return fileURL.lastPathComponent }
        let firstLine = content
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? ""
        var t = firstLine
        while t.hasPrefix("#") { t.removeFirst() }
        t = t.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? "無題" : String(t.prefix(30))
    }
}
