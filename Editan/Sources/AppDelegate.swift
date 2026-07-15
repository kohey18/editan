import AppKit

/// Finder からのファイルオープン(ダブルクリック /「このアプリケーションで開く」)を受け取る。
/// 起動直後など BufferStore が接続される前に届いた URL は保留し、接続時にまとめて開く。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var store: BufferStore? {
        didSet { openPendingURLs() }
    }
    private var pendingURLs: [URL] = []

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
