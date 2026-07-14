import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var store: BufferStore

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
        }
        CommandGroup(after: .toolbar) {
            Button(store.showPreview ? "プレビューを隠す" : "プレビューを表示") {
                store.showPreview.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
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
