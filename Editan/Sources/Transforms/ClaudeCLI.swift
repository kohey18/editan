import Foundation

enum CLIError: LocalizedError {
    case notFound
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "claude コマンドが見つかりませんでした。Claude Code CLI がインストールされているか確認してください。"
        case .failed(let message):
            return message.isEmpty ? "変換に失敗しました。" : message
        }
    }
}

/// Claude Code CLI のヘッドレスモード(claude -p)でテキスト変換を行う。
/// API 課金ではなく Claude サブスクリプションの認証をそのまま使う。
enum ClaudeCLI {
    private static let pathKey = "claudeCLIPath"

    static func transform(instruction: String, input: String, model: String) async throws -> String {
        let executable = try await executablePath()
        return try await run(
            executable: executable,
            arguments: ["-p", instruction, "--model", model],
            stdin: input
        )
    }

    private static func executablePath() async throws -> String {
        if let cached = UserDefaults.standard.string(forKey: pathKey),
           FileManager.default.isExecutableFile(atPath: cached) {
            return cached
        }
        let home = NSHomeDirectory()
        let candidates = [
            "\(home)/.claude/local/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            "\(home)/.local/bin/claude",
        ]
        if let found = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            UserDefaults.standard.set(found, forKey: pathKey)
            return found
        }
        // GUI アプリの PATH には入っていないことが多いので、ログインシェルの PATH から探す
        if let output = try? await run(executable: "/bin/zsh", arguments: ["-lc", "command -v claude"], stdin: "") {
            let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) {
                UserDefaults.standard.set(path, forKey: pathKey)
                return path
            }
        }
        throw CLIError.notFound
    }

    private static func run(executable: String, arguments: [String], stdin input: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                var environment = ProcessInfo.processInfo.environment
                environment["PATH"] = (environment["PATH"] ?? "") + ":/opt/homebrew/bin:/usr/local/bin"
                process.environment = environment

                let stdinPipe = Pipe()
                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardInput = stdinPipe
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                if let data = input.data(using: .utf8), !data.isEmpty {
                    stdinPipe.fileHandleForWriting.write(data)
                }
                try? stdinPipe.fileHandleForWriting.close()

                let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    continuation.resume(returning: String(data: outData, encoding: .utf8) ?? "")
                } else {
                    let message = String(data: errData, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    continuation.resume(throwing: CLIError.failed(message))
                }
            }
        }
    }
}
