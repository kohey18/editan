import SwiftUI

@main
struct EditanApp: App {
    @StateObject private var store = BufferStore()
    @StateObject private var transforms = TransformStore()

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

        Settings {
            TransformSettingsView()
                .environmentObject(transforms)
        }
    }
}
