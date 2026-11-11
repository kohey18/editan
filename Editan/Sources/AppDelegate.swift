import AppKit

/// Finder からのファイルオープン(ダブルクリック /「このアプリケーションで開く」)を受け取る。
/// 起動直後など BufferStore が接続される前に届いた URL は保留し、接続時にまとめて開く。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var store: BufferStore? {
        didSet { openPendingURLs() }
    }
    private var pendingURLs: [URL] = []
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // ⌘+ / ⌘- / ⌘0 のズーム。US 配列の ⌘= や JIS 配列の ⌘; でも拡大できるよう、
        // メニューの key equivalent より先にローカルモニタで拾う
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, let store = self.store, Self.handleZoomKey(event, store: store) else { return event }
                return nil
            }
        }
    }

    private static func handleZoomKey(_ event: NSEvent, store: BufferStore) -> Bool {
        let flags = event.modifierFlags.intersection([.command, .option, .control])
        guard flags == .command, let key = event.charactersIgnoringModifiers else { return false }
        switch key {
        case "+", "=", ";": store.zoomIn()
        case "-", "_": store.zoomOut()
        case "0": store.resetZoom()
        default: return false
        }
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        pendingURLs.append(contentsOf: urls)
        openPendingURLs()
    }

    private func openPendingURLs() {
        guard let store, !pendingURLs.isEmpty else { return }
        let urls = pendingURLs
        pendingURLs = []
        for url in urls { store.openFile(at: url) }
        AppActivator.activate()
    }
}
