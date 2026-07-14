import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var store: BufferStore
    @ObservedObject var transforms: TransformStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("新規バッファ") { store.newBuffer() }
                .keyboardShortcut("n", modifiers: .command)
            Button("開く…") { store.openDocument() }
                .keyboardShortcut("o", modifiers: .command)
        }
        CommandGroup(replacing: .saveItem) {
            Button("保存") { store.saveSelected() }
                .keyboardShortcut("s", modifiers: .command)
            Button("別名で保存…") { store.saveSelectedAs() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            Divider()
            Button("Notion に送る") { store.sendToNotion() }
                .keyboardShortcut("n", modifiers: [.command, .shift])
        }
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Slack 用にコピー") { store.copyForSlack() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            Button("リッチテキストとしてコピー") { store.copyAsRichText() }
                .keyboardShortcut("c", modifiers: [.command, .option])
            Divider()
            Button("Markdown を整形") { store.formatMarkdown() }
                .keyboardShortcut("f", modifiers: [.command, .shift])
        }
        CommandGroup(after: .toolbar) {
            Button(store.showPreview ? "プレビューを隠す" : "プレビューを表示") {
                store.showPreview.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
        }
        CommandMenu("変換") {
            ForEach(Array(transforms.templates.prefix(9).enumerated()), id: \.element.id) { pair in
                Button(pair.element.name) {
                    transforms.run(pair.element)
                }
                .keyboardShortcut(
                    KeyEquivalent(Character("\(pair.offset + 1)")),
                    modifiers: [.command, .option]
                )
            }
            Divider()
            Button("テンプレートを編集…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        CommandMenu("バッファ") {
            ForEach(Array(store.buffers.prefix(9).enumerated()), id: \.element.id) { pair in
                Button(pair.element.title) {
                    store.selectedID = pair.element.id
                }
                .keyboardShortcut(
                    KeyEquivalent(Character("\(pair.offset + 1)")),
                    modifiers: .command
                )
            }
            Divider()
            Button("バッファを削除") {
                if let id = store.selectedID { store.deleteBuffer(id) }
            }
            .keyboardShortcut(.delete, modifiers: .command)
        }
    }
}
