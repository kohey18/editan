import Foundation

enum NotionError: LocalizedError {
    case notConfigured
    case api(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Notion の Integration Token と親ページ ID を設定してください(設定 → Notion)。"
        case .api(let message):
            return message
        }
    }
}

enum NotionClient {
    static var isConfigured: Bool {
        let defaults = UserDefaults.standard
        return !((try? NotionCredentials.load()) ?? "").isEmpty
            && !(defaults.string(forKey: "notionParentPageID") ?? "").isEmpty
    }

    /// 親ページ配下に新規ページを作成し、ページ URL を返す。
    static func createPage(title: String, markdown: String) async throws -> URL? {
        let defaults = UserDefaults.standard
        let token = try NotionCredentials.load()
        guard !token.isEmpty,
              let parent = defaults.string(forKey: "notionParentPageID"), !parent.isEmpty else {
            throw NotionError.notConfigured
        }

        let blocks = NotionBlocks.convert(markdown)
        let payload: [String: Any] = [
            "parent": ["page_id": parent.trimmingCharacters(in: .whitespaces)],
            "properties": ["title": ["title": [["text": ["content": title]]]]],
            "children": Array(blocks.prefix(100)),
        ]
        let json = try await request(
            "POST", "https://api.notion.com/v1/pages", token: token, body: payload
        )
        let pageID = json["id"] as? String

        // Notion API は 1 リクエスト 100 ブロックまでなので、超過分を追記する
        var rest = Array(blocks.dropFirst(100))
        while !rest.isEmpty, let pageID {
            let chunk = Array(rest.prefix(100))
            rest.removeFirst(chunk.count)
            _ = try await request(
                "PATCH", "https://api.notion.com/v1/blocks/\(pageID)/children",
                token: token, body: ["children": chunk]
            )
        }

        return (json["url"] as? String).flatMap(URL.init(string:))
    }

    private static func request(
        _ method: String, _ urlString: String, token: String, body: [String: Any]
    ) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = method
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = json["message"] as? String
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NotionError.api(message ?? "Notion API エラー (HTTP \(status))")
        }
        return json
    }
}
