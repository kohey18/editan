import Foundation
import Security

/// The login Keychain supports the app's ad-hoc signed, source-built distribution.
/// Never fall back to writing a credential to preferences when Keychain access fails.
enum NotionCredentials {
    private static let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "io.github.kohey18.editan.notion",
        kSecAttrAccount as String: "integration-token",
    ]

    struct KeychainError: LocalizedError {
        let status: OSStatus
        var errorDescription: String? {
            "Notion トークンの Keychain 操作に失敗しました (\(status))。Keychain のロックとアクセス許可を確認してください。"
        }
    }

    static func read() throws -> String {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            throw KeychainError(status: errSecDecode)
        }
        return token
    }

    static func save(_ token: String) throws {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError(status: status)
            }
        } else {
            let attributes = [kSecValueData as String: Data(trimmed.utf8)]
            var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status == errSecItemNotFound {
                status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
            }
            guard status == errSecSuccess else { throw KeychainError(status: status) }
        }
        UserDefaults.standard.removeObject(forKey: "notionToken")
    }

    static func load() throws -> String {
        try migrateLegacyToken(defaults: .standard, read: read, save: save)
    }

    /// Remove the old preference only after a successful Keychain read/write.
    /// Injectable operations let migration failures be tested without real credentials.
    static func migrateLegacyToken(
        defaults: UserDefaults, read: () throws -> String, save: (String) throws -> Void
    ) throws -> String {
        let current = try read()
        guard let legacy = defaults.string(forKey: "notionToken") else { return current }
        if current.isEmpty && !legacy.isEmpty {
            try save(legacy)
        }
        defaults.removeObject(forKey: "notionToken")
        return current.isEmpty ? legacy : current
    }
}
