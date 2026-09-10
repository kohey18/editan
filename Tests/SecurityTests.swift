import XCTest

final class SecurityTests: XCTestCase {
    func testProcessDrainsLargeStderrWithoutDeadlocking() async throws {
        let result = try await ClaudeCLI.run(
            executable: "/bin/sh",
            arguments: ["-c", "head -c 131072 /dev/zero >&2; printf done"], stdin: ""
        )
        XCTAssertEqual(result, "done")
    }

    func testProcessReturnsFailureWithoutTreatingOutputAsSuccess() async {
        do {
            _ = try await ClaudeCLI.run(
                executable: "/bin/sh", arguments: ["-c", "printf failure >&2; exit 1"], stdin: ""
            )
            XCTFail("Expected failure")
        } catch {
            XCTAssertEqual(error.localizedDescription, "failure")
        }
    }

    func testRawHTMLCannotBecomeActiveMarkup() {
        let html = MarkdownRenderer.body(from: "<script>alert(1)</script>\n\n<img src=x onerror=alert(1)>")
        XCTAssertFalse(html.contains("<script>"))
        XCTAssertFalse(html.contains("<img src=x"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    func testCodeAndLinkAttributesAreEscaped() {
        let html = MarkdownRenderer.body(from: "`<script>&`\n\n[link](https://example.com/?x=%22)\n\n```swift\n</code><script>alert(1)</script>\n```")
        XCTAssertFalse(html.contains("<script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;&amp;"))
        XCTAssertTrue(html.contains("href=\"https://example.com/"))
    }

    func testUnsafeURLSchemesAreRemoved() {
        for scheme in ["javascript", "vbscript", "file", "data"] {
            let html = MarkdownRenderer.body(from: "[link](\(scheme):payload)")
            XCTAssertFalse(html.contains("href="), scheme)
        }
        let html = MarkdownRenderer.body(from: "[mail](mailto:hello@example.com)")
        XCTAssertTrue(html.contains("href=\"mailto:"))
    }

    func testPreviewBlocksRemoteResources() {
        let html = MarkdownRenderer.html(from: "![remote](https://example.com/tracker.png)")
        XCTAssertTrue(html.contains("default-src 'none'"))
        XCTAssertTrue(html.contains("img-src data:"))
        XCTAssertFalse(html.contains("img-src https:"))
    }

    func testMigrationRemovesPreferenceAfterSuccessfulSave() throws {
        try withDefaults { defaults in
            defaults.set("legacy-example", forKey: "notionToken")
            var saved = ""
            let token = try NotionCredentials.migrateLegacyToken(defaults: defaults, read: { "" }, save: { saved = $0 })
            XCTAssertEqual(saved, "legacy-example")
            XCTAssertEqual(token, saved)
            XCTAssertNil(defaults.object(forKey: "notionToken"))
        }
    }

    func testMigrationRetainsPreferenceWhenKeychainWriteFails() throws {
        try withDefaults { defaults in
            defaults.set("legacy-example", forKey: "notionToken")
            XCTAssertThrowsError(try NotionCredentials.migrateLegacyToken(
                defaults: defaults, read: { "" }, save: { _ in throw TestError.denied }
            ))
            XCTAssertEqual(defaults.string(forKey: "notionToken"), "legacy-example")
        }
    }

    func testMigrationRetainsPreferenceWhenKeychainReadFails() throws {
        try withDefaults { defaults in
            defaults.set("legacy-example", forKey: "notionToken")
            XCTAssertThrowsError(try NotionCredentials.migrateLegacyToken(
                defaults: defaults, read: { throw TestError.denied }, save: { _ in XCTFail("Unexpected write") }
            ))
            XCTAssertEqual(defaults.string(forKey: "notionToken"), "legacy-example")
        }
    }

    func testMigrationDoesNotOverwriteExistingCredential() throws {
        try withDefaults { defaults in
            defaults.set("legacy-example", forKey: "notionToken")
            let token = try NotionCredentials.migrateLegacyToken(
                defaults: defaults, read: { "current-example" }, save: { _ in XCTFail("Unexpected overwrite") }
            )
            XCTAssertEqual(token, "current-example")
            XCTAssertNil(defaults.object(forKey: "notionToken"))
        }
    }

    func testTransformDisablesToolsAndKeepsInstructionAsOneArgument() {
        let instruction = "Rewrite this; $(touch /tmp/never-execute)\n--tools Bash"
        let args = ClaudeCLI.transformArguments(instruction: instruction, model: "sonnet")
        XCTAssertEqual(args[1], instruction)
        XCTAssertEqual(value(after: "--tools", in: args), "")
        XCTAssertEqual(value(after: "--mcp-config", in: args), "{\"mcpServers\":{}}")
        XCTAssertEqual(value(after: "--disallowedTools", in: args), "mcp__*")
        XCTAssertEqual(value(after: "--setting-sources", in: args), "")
        XCTAssertEqual(value(after: "--settings", in: args), "{\"disableAllHooks\":true}")
        XCTAssertTrue(args.contains("--strict-mcp-config"))
        XCTAssertTrue(args.contains("--safe-mode"))
        XCTAssertTrue(args.contains("--no-session-persistence"))
        XCTAssertFalse(args.contains("--dangerously-skip-permissions"))
    }

    private enum TestError: Error { case denied }

    private func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    private func withDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let name = "EditanSecurityTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }
}
