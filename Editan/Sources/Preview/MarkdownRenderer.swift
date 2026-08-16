import Foundation
import Markdown

/// ソフト改行(単一の改行)を <br> として描画させる。
/// エディタ上の改行がそのままプレビューに反映される(GitHub コメントと同じ挙動)。
private struct HardLineBreaks: MarkupRewriter {
    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> Markup? {
        LineBreak()
    }
}

enum MarkdownRenderer {
    /// ページ装飾なしの HTML 本文。リッチテキストコピー(Gmail 貼り付け等)にも使う。
    static func body(from markdown: String) -> String {
        var document = Document(parsing: markdown)
        var rewriter = HardLineBreaks()
        if let rewritten = rewriter.visit(document) as? Document {
            document = rewritten
        }
        return SafeHTMLFormatter.format(document)
    }

    static func html(from markdown: String) -> String {
        let body = body(from: markdown)
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; img-src data:;">
        <style>\(css)</style>
        <style>
        @media (prefers-color-scheme: light) { \(themeLight) }
        @media (prefers-color-scheme: dark) { \(themeDark) }
        pre code.hljs { background: transparent; padding: 0; }
        </style>
        <script>\(highlightJS)</script>
        </head>
        <body><article>\(body)</article>
        <script>\(setupScript)</script>
        </body>
        </html>
        """
    }

    // MARK: - highlight.js(同梱、オフライン動作)

    private static let highlightJS = loadResource("highlight.min", "js")
    private static let themeLight = loadResource("github.min", "css")
    private static let themeDark = loadResource("github-dark.min", "css")

    private static func loadResource(_ name: String, _ ext: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let content = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return content
    }

    /// コードブロックのハイライト適用 + ホバーで出るコピーボタン
    private static let setupScript = """
    if (window.hljs) { hljs.highlightAll(); }
    document.querySelectorAll('pre').forEach(function (pre) {
        var btn = document.createElement('button');
        btn.className = 'copy-btn';
        btn.textContent = 'コピー';
        btn.addEventListener('click', function () {
            var code = pre.querySelector('code');
            var text = code ? code.innerText : pre.innerText;
            try { window.webkit.messageHandlers.copyCode.postMessage(text); } catch (e) {}
            btn.textContent = '✓ コピーしました';
            btn.classList.add('copied');
            setTimeout(function () {
                btn.textContent = 'コピー';
                btn.classList.remove('copied');
            }, 1500);
        });
        pre.appendChild(btn);
    });
    """

    private static let css = """
    :root { color-scheme: light dark; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Hiragino Sans", sans-serif;
        font-size: 15px;
        line-height: 1.6;
        margin: 0;
        padding: 24px 32px;
        -webkit-text-size-adjust: 100%;
    }
    article { max-width: 720px; margin: 0 auto; }
    p { margin: .6em 0; }
    ul, ol { margin: .4em 0; padding-left: 1.5em; }
    li { margin: .1em 0; }
    li > p { margin: 0; }
    li > ul, li > ol { margin: .1em 0; }
    h1, h2 { border-bottom: 1px solid rgba(128,128,128,.3); padding-bottom: .3em; }
    h1 { font-size: 1.7em; }
    h2 { font-size: 1.4em; }
    code {
        font-family: "SF Mono", Menlo, monospace;
        font-size: .88em;
        background: rgba(128,128,128,.16);
        padding: .12em .35em;
        border-radius: 4px;
    }
    pre {
        background: rgba(128,128,128,.12);
        padding: 12px 16px;
        border-radius: 8px;
        overflow-x: auto;
        line-height: 1.55;
        position: relative;
    }
    pre code { background: none; padding: 0; }
    .copy-btn {
        position: absolute;
        top: 6px;
        right: 6px;
        font-size: 11px;
        font-family: -apple-system, sans-serif;
        padding: 3px 9px;
        border-radius: 5px;
        border: 1px solid rgba(128,128,128,.4);
        background: rgba(128,128,128,.18);
        color: inherit;
        cursor: pointer;
        opacity: 0;
        transition: opacity .15s;
    }
    pre:hover .copy-btn { opacity: 1; }
    .copy-btn:hover { background: rgba(128,128,128,.3); }
    .copy-btn.copied { opacity: 1; border-color: rgba(60,180,90,.7); }
    blockquote {
        margin: 0 0 1em;
        padding: 0 1em;
        border-left: 4px solid rgba(128,128,128,.4);
        opacity: .8;
    }
    table { border-collapse: collapse; margin: 1em 0; }
    th, td { border: 1px solid rgba(128,128,128,.4); padding: 6px 12px; }
    th { background: rgba(128,128,128,.12); }
    img { max-width: 100%; }
    hr { border: none; border-top: 1px solid rgba(128,128,128,.3); margin: 2em 0; }
    a { color: #0969da; }
    @media (prefers-color-scheme: dark) {
        a { color: #4493f8; }
    }
    """
}
