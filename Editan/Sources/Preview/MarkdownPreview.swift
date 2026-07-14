import SwiftUI
import WebKit

struct MarkdownPreview: NSViewRepresentable {
    let markdown: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.render(markdown: markdown)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        private var pending: DispatchWorkItem?
        private var lastRendered: String?
        private var savedScrollY: Double = 0

        func render(markdown: String) {
            guard markdown != lastRendered else { return }
            pending?.cancel()
            let work = DispatchWorkItem { [weak self] in self?.reload(markdown) }
            pending = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
        }

        private func reload(_ markdown: String) {
            lastRendered = markdown
            guard let webView else { return }
            // リロード前にスクロール位置を退避し、didFinish で復元する
            webView.evaluateJavaScript("window.scrollY") { [weak self] y, _ in
                guard let self, let webView = self.webView else { return }
                self.savedScrollY = (y as? Double) ?? 0
                webView.loadHTMLString(MarkdownRenderer.html(from: markdown), baseURL: nil)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if savedScrollY > 0 {
                webView.evaluateJavaScript("window.scrollTo(0, \(savedScrollY));", completionHandler: nil)
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
