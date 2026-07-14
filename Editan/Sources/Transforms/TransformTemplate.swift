import Foundation

struct TransformTemplate: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var prompt: String

    static let defaults: [TransformTemplate] = [
        TransformTemplate(
            name: "敬語に変換(メール)",
            prompt: "以下のテキストを、ビジネスメールとして自然で適切な敬語の日本語に書き換えてください。内容や意図は変えないでください。宛名・署名・件名など元のテキストにない要素は追加しないでください。書き換え後の本文のみを出力し、説明や前置きは一切不要です。"
        ),
        TransformTemplate(
            name: "カジュアルに変換",
            prompt: "以下のテキストを、社内チャット向けのカジュアルで簡潔な日本語に書き換えてください。内容は変えないでください。書き換え後の本文のみを出力し、説明や前置きは一切不要です。"
        ),
        TransformTemplate(
            name: "校正",
            prompt: "以下のテキストの誤字脱字・文法・不自然な表現を修正してください。文体やトーンは維持してください。修正後の本文のみを出力し、説明や前置きは一切不要です。"
        ),
        TransformTemplate(
            name: "要約",
            prompt: "以下のテキストを、重要なポイントを保ちながら簡潔に要約してください。箇条書きが適切な場合は Markdown の箇条書きを使ってください。要約のみを出力し、説明や前置きは一切不要です。"
        ),
    ]
}
