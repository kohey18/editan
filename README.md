<p align="center">
  <img src="docs/icon.png" width="96" height="96" alt="Editan — a little paper companion">
</p>
<h1 align="center">Editan</h1>
<p align="center"><strong>Write here. Paste anywhere.</strong><br>A little space on your Mac for text headed somewhere else.</p>
<p align="center">
  <a href="#getting-started"><img src="https://img.shields.io/badge/macOS-14%2B-264536?logo=apple&amp;logoColor=white" alt="macOS 14 or later"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-264536" alt="MIT License"></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/contributions-welcome-264536" alt="Contributions welcome"></a>
</p>
<p align="center"><a href="https://kohey18.github.io/editan/">Website</a> · <a href="#getting-started">Get started</a> · <a href="#keyboard-shortcuts">Shortcuts</a> · <a href="README.ja.md">日本語</a></p>

![Editan drafting sample release notes with Markdown syntax highlighting and a live preview](docs/demo.gif)

Your next AI prompt. A carefully worded email. A team update that needs to survive a paste into Slack. **Editan is a native macOS staging editor for all the text you write for other apps.**

Draft in a scratch buffer, refine the words, copy in the right format, and get back to what you were doing. No Editan account or cloud sync. Editing and preview work offline; optional Claude and Notion integrations send text only when you run them.

> **Early-stage software.** Build from source for now; there is no notarized download or App Store release. The app currently uses Japanese UI labels. English and Japanese documentation are available.

## Why Editan?

- **A scratchpad without the housekeeping.** Scratch buffers save automatically as Markdown files. Open and edit existing text files, too.
- **A clipboard you can predict.** Standard **⌘C always copies plain text**. Slack-style text and rich text each have their own explicit command.
- **Markdown with a view.** Syntax highlighting, a split preview, a formatter, list continuation, and copyable code blocks.
- **Help with the words, when you want it.** Optional Claude Code transforms for polite Japanese, a casual tone, proofreading, summaries, or your own instructions. Review before replacing.
- **Made for your Mac.** SwiftUI + AppKit, a menu bar companion, a global hotkey, reusable snippets, and editing that respects Japanese IME composition.

## One draft, several destinations

| Where it is going | What Editan does | Shortcut |
| --- | --- | --- |
| An AI prompt, a terminal, anywhere | Copy plain text without hidden formatting | ⌘C |
| Slack | Convert to Slack-style text and copy it | ⇧⌘C |
| Gmail, Pages, other rich-text apps | Copy HTML with a plain-text fallback | ⌥⌘C |
| Notion | Create a page under your configured parent page | ⇧⌘N |

Slack copy puts text on your clipboard; it does not post a message. Notion export sends the current buffer through the Notion API. How rich text and Slack-style text appear depends on the destination app.

## Getting started

**Requirements:** macOS 14+, full **Xcode 26+** (including its command-line tools), and [Homebrew](https://brew.sh/). The pinned Markdown dependencies use Swift tools 6.2; Editan's source uses Swift 5 language mode.

```sh
brew install xcodegen
git clone https://github.com/kohey18/editan.git
cd editan
./Scripts/install.sh
```

The script builds Release and installs `/Applications/Editan.app`, replacing an existing copy. Open Editan from Applications, or press **⌥⌘E** once it is running.

1. Press **⌘N** for a scratch buffer and write something.
2. Toggle the preview with **⇧⌘P** or format Markdown with **⇧⌘F**.
3. Copy with **⌘C**, **⇧⌘C**, or **⌥⌘C**, then paste into the destination.

Scratch buffers auto-save. Existing files use **⌘S**. Closing a scratch buffer deletes that draft after confirmation.

<details>
<summary><strong>Optional: Claude transforms</strong></summary>

Install and authenticate the [Claude Code CLI](https://code.claude.com/docs/en/overview). Use a recent version supporting the flags documented in [the security policy](SECURITY.md#claude-transforms).

In Settings (**⌘,**) → 変換, choose a model and edit transformation templates. Select text, or leave nothing selected to transform the full draft, then use the 変換 menu or **⌥⌘1–9**. Review the result before replacing the original or copying it.

Editan runs `claude -p` with built-in tools, MCP tools, slash commands, hooks, and session persistence disabled (administrator-managed policy may still apply). Your CLI authentication, provider configuration, usage limits, and billing still apply. A Claude subscription is not an unconditional guarantee of zero additional charges.

</details>

<details>
<summary><strong>Optional: Notion export</strong></summary>

1. Create a Notion internal integration and connect it to the destination parent page.
2. In Settings (**⌘,**) → Notion, enter the integration token and parent page ID.
3. Click **トークンを Keychain に保存** to save the token to macOS Keychain.
4. Press **⇧⌘N** to create a new page from the current buffer.

The token is kept in macOS Keychain. Legacy tokens in preferences migrate when the Notion settings or export path is used; preferences are removed only after successful migration. Keychain access may ask for confirmation after rebuilding an ad-hoc signed app.

</details>

## Keyboard shortcuts

⌘ Command · ⇧ Shift · ⌥ Option · ⌃ Control

| Action | Shortcut | Action | Shortcut |
| --- | --- | --- | --- |
| Summon Editan | ⌥⌘E | Plain-text copy | ⌘C |
| New buffer | ⌘N | Copy for Slack | ⇧⌘C |
| Switch buffer | ⌘1–9 | Rich-text copy | ⌥⌘C |
| Close buffer (with confirmation) | ⌘W | Send to Notion | ⇧⌘N |
| Open file | ⌘O | Format Markdown | ⇧⌘F |
| Save / Save As | ⌘S / ⇧⌘S | Toggle preview | ⇧⌘P |
| Find | ⌘F | Insert snippet | ⌃⌘1–9 |
| Settings | ⌘, | Run transform | ⌥⌘1–9 |

## Your data

| Data | Location / behavior |
| --- | --- |
| Scratch drafts | `~/Library/Application Support/Editan/Buffers/<uuid>.md` |
| Buffer index and templates | `~/Library/Application Support/Editan/` |
| Opened files | Their original location; save explicitly |
| Notion token | macOS Keychain; parent page ID remains in preferences |
| Claude transform | Selected text or full draft sent through your configured CLI |
| Notion export | Current buffer sent to the Notion API |

Editan has no analytics, crash-reporting service, automatic update checks, or cloud sync. Drafts are plain files, **not encrypted by Editan**. The preview blocks remote resources and escapes raw HTML. Exported rich text can contain remote image URLs, which a receiving app may load. See [SECURITY.md](SECURITY.md) for the boundaries and reporting process.

## Development

```sh
xcodegen generate
open Editan.xcodeproj

# Build the native app
xcodebuild -project Editan.xcodeproj -scheme Editan \
  -configuration Debug -derivedDataPath build/DerivedData build

# Run the isolated security regression tests
xcodebuild -project Editan.xcodeproj -scheme EditanSecurityTests \
  -destination 'platform=macOS' -derivedDataPath build/DerivedData test
```

`project.yml` is the source of truth; the generated `.xcodeproj` is ignored. Regenerate after adding, moving, or removing Swift files. Security tests run without launching the app or reading real Notion credentials.

| Area | Responsibility |
| --- | --- |
| `Models/` | Buffers, persistence, editor commands |
| `Editor/` | AppKit text view, plain-text clipboard, highlighting, IME handling |
| `Preview/` | Safe Markdown-to-HTML conversion and the WebKit preview |
| `Transforms/` · `Formats/` | Claude subprocess, Slack conversion, reusable templates |
| `Notion/` | Block conversion, Keychain credentials, API export |
| `Views/` · `Utils/` | SwiftUI interface, global hotkey, editor access |
| `docs/` | Static English/Japanese landing page for GitHub Pages |

See [CONTRIBUTING.md](CONTRIBUTING.md) for checks, [website maintenance](docs/website.md) for Pages, and [third-party notices](THIRD_PARTY_NOTICES.md) for dependencies.

## What's next

Ideas under consideration, not promises of shipped features:

- Preview scroll synchronization
- Buffer search, pinning, and drag reordering
- A diff view for transform results
- More LLM providers and English app localization
- Signed and notarized distribution

Have a use case or a small improvement? [Open an issue](https://github.com/kohey18/editan/issues) or [contribute a pull request](CONTRIBUTING.md). Bug reports, documentation, and Japanese IME testing all help.

## License

[MIT](LICENSE) © 2026 [kohey18](https://github.com/kohey18). Built with [swift-markdown](https://github.com/swiftlang/swift-markdown), [swift-cmark](https://github.com/swiftlang/swift-cmark), and [highlight.js](https://highlightjs.org/).
