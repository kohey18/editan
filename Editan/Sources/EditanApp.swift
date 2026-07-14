import SwiftUI

@main
struct EditanApp: App {
    @StateObject private var store = BufferStore()
    @StateObject private var transforms = TransformStore()

    init() {
        HotKeyManager.shared.register()
    }

    var body: some Scene {
        Window("Editan", id: "main") {
            ContentView()
                .environmentObject(store)
                .environmentObject(transforms)
        }
        .defaultSize(width: 1100, height: 700)
        .commands {
            AppCommands(store: store, transforms: transforms)
        }

        MenuBarExtra("Editan", systemImage: "arrow.up.doc") {
            Button("Editan を開く (⌥⌘E)") {
                AppActivator.activate()
            }
            Button("新規バッファ") {
                AppActivator.activate()
                store.newBuffer()
            }
            Divider()
            Button("Editan を終了") {
                NSApp.terminate(nil)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(transforms)
        }
    }
}
