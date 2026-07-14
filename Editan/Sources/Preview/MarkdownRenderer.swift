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
    static func html(from markdown: String) -> String {
        var document = Document(parsing: markdown)
        var rewriter = HardLineBreaks()
        if let rewritten = rewriter.visit(document) as? Document {
            document = rewritten
        }
        let body = HTMLFormatter.format(document)
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>\(css)</style>
        </head>
        <body><article>\(body)</article></body>
        </html>
        """
    }

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
    }
    pre code { background: none; padding: 0; }
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
