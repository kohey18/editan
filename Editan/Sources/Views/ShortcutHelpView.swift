import SwiftUI

struct ShortcutHelpView: View {
    private struct Shortcut: Identifiable {
        let key: String
        let label: String
        var id: String { key }
    }

    private struct Group: Identifiable {
        let title: String
        let items: [Shortcut]
        var id: String { title }
    }

    private let groups: [Group] = [
        Group(title: "バッファ", items: [
            Shortcut(key: "⌘N", label: "新規バッファ"),
            Shortcut(key: "⌘1〜9", label: "バッファ切替"),
            Shortcut(key: "⌘⌫", label: "バッファを削除"),
            Shortcut(key: "⌘O", label: "ファイルを開く"),
            Shortcut(key: "⌘S", label: "保存"),
            Shortcut(key: "⇧⌘S", label: "別名で保存"),
        ]),
        Group(title: "コピー", items: [
            Shortcut(key: "⌘C", label: "コピー(常にプレーン)"),
            Shortcut(key: "⇧⌘C", label: "Slack 用にコピー"),
            Shortcut(key: "⌥⌘C", label: "リッチテキストとしてコピー"),
        ]),
        Group(title: "Markdown", items: [
            Shortcut(key: "⇧⌘F", label: "Markdown を整形"),
            Shortcut(key: "⇧⌘P", label: "プレビュー表示切替"),
        ]),
        Group(title: "変換 (LLM)", items: [
            Shortcut(key: "⌥⌘1〜9", label: "変換テンプレート実行"),
            Shortcut(key: "⌘,", label: "設定(テンプレート編集)"),
        ]),
        Group(title: "その他", items: [
            Shortcut(key: "⌘F", label: "検索"),
        ]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(group.items) { item in
                        HStack {
                            Text(item.key)
                                .font(.system(.callout, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                                .frame(minWidth: 72, alignment: .leading)
                            Text(item.label)
                                .font(.callout)
                        }
                    }
                }
            }
            Divider()
            Text("⌘ command ⇧ shift ⌥ option ⌫ delete")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(width: 300, alignment: .leading)
    }
}
