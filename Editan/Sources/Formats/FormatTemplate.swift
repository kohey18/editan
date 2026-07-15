import Foundation

struct FormatTemplate: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var content: String

    static let defaults: [FormatTemplate] = [
        FormatTemplate(
            name: "日報",
            content: """
            # 日報 {{date}} ({{weekday}})

            ## 今日やったこと

            - {{cursor}}

            ## 明日やること

            -\u{0020}

            ## メモ

            -\u{0020}
            """
        ),
        FormatTemplate(
            name: "議事録",
            content: """
            # {{cursor}} 議事録

            - 日時: {{date}} {{time}}
            - 参加者:\u{0020}

            ## アジェンダ

            -\u{0020}

            ## 決定事項

            -\u{0020}

            ## TODO

            - [ ]\u{0020}
            """
        ),
    ]
}
