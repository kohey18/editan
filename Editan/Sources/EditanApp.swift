import SwiftUI

@main
struct EditanApp: App {
    @StateObject private var store = BufferStore()

    var body: some Scene {
        Window("Editan", id: "main") {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 1100, height: 700)
        .commands {
            AppCommands(store: store)
        }
    }
}
