<p align="center">
  <img src="docs/icon.png" width="128" alt="Editan icon">
</p>

<h1 align="center">Editan</h1>

<p align="center">
  <b>A staging editor for macOS: write → transform → copy → paste anywhere.</b>
</p>

<p align="center">
  <a href="#installation"><img src="https://img.shields.io/badge/macOS-14%2B-blue?logo=apple" alt="macOS 14+"></a>
  <img src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white" alt="Swift 5">
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-purple" alt="SwiftUI + AppKit">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License"></a>
  <a href="#contributing"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen" alt="PRs welcome"></a>
</p>

---

Editan is the place to write text that ends up in **other apps** — prompts for Claude Code, email bodies for Gmail, Markdown for Slack or Notion. Draft it here, transform it with an LLM if you want, then copy it in exactly the format the destination expects.

No cloud sync. No telemetry. No account. Everything stays on your Mac.

![Editan demo: typing Markdown release notes in the editor while the preview pane renders them live with per-language code highlighting](docs/demo.gif)

## Why Editan?

Most text you write on a computer is destined for a paste. But every destination wants something different: Slack mangles Markdown, Gmail wants rich text, Claude Code wants plain prompts, and Notion wants blocks. Editan is built around that one workflow:

1. **Write** in a scratch buffer — no save dialogs, everything auto-persists
2. **Transform** with an LLM if needed — politeness rewrite, proofread, summarize, or your own template
3. **Copy** in the right flavor — plain, Slack mrkdwn, rich text, or straight into Notion
4. **Paste** and move on

## Features

### Editor

- **⌘C always copies plain text** — rich text never sneaks into your clipboard
- Scratch-buffer based: buffers auto-save as Markdown files, no "Untitled.txt" dialogs; regular `.md` files can be opened and edited too
- Markdown syntax highlighting, list/quote continuation on newline, and a formatter (⇧⌘F)
- Japanese IME-safe: highlighting and newline handling never interfere with text composition
- Smart quotes and autocorrect are always off

### Preview

- Split-pane Markdown preview with per-language code highlighting (highlight.js bundled, works offline)
- Copy button on every code block
- Links open in your default browser

### Copy & export

- **⇧⌘C** — copy for Slack (mrkdwn-style: bold/italic/strikethrough, lists, quotes)
- **⌥⌘C** — copy as rich text (pastes formatted into Gmail, Pages, …)
- **⇧⌘N** — send the current buffer to Notion as a new page (rich text annotations preserved)

### LLM transforms

- Rewrite selections or whole buffers: keigo (polite Japanese), casual, proofread, summarize — or define your own templates
- Runs via the **Claude Code CLI (`claude -p`) as a subprocess** — works within your existing Claude subscription, no API key, no extra billing
- Review the result in a sheet, then replace the text or copy it

### Always within reach

- Global hotkey **⌥⌘E** and a menu bar extra bring Editan up from anywhere
- Registers as a Markdown/plain-text editor, so files open from Finder too

## Keyboard shortcuts

| Buffers | | Copy | |
|---|---|---|---|
| ⌘N | New buffer | ⌘C | Copy (always plain) |
| ⌘1–9 | Switch buffer | ⇧⌘C | Copy for Slack |
| ⌘W | Close buffer | ⌥⌘C | Copy as rich text |
| ⌘O | Open file | | |
| ⌘S / ⇧⌘S | Save / Save As | | |

| Markdown & transforms | | Other | |
|---|---|---|---|
| ⇧⌘F | Format Markdown | ⌘F | Find |
| ⇧⌘P | Toggle preview | ⌥⌘E | Summon Editan from anywhere |
| ⌃⌘1–9 | Insert format template | ⇧⌘N | Send to Notion |
| ⌥⌘1–9 | Run LLM transform | ⌘, | Settings |

## Installation

### Build from source (recommended)

```sh
# Prerequisites: macOS 14+, Xcode 16+ (App Store), Homebrew
xcode-select --install            # if not installed yet
brew install xcodegen
git clone https://github.com/kohey18/editan.git
cd editan
./Scripts/install.sh              # builds Release and installs /Applications/Editan.app
```

### Copy a prebuilt .app

Copy `/Applications/Editan.app` from a Mac that built it (AirDrop, USB, etc.) into the other Mac's `/Applications`. The app is ad-hoc signed (not notarized), so if the first launch is blocked:

```sh
xattr -dr com.apple.quarantine /Applications/Editan.app
```

or right-click the app in Finder and choose "Open".

### Optional integrations

- **LLM transforms** require the [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude`) installed and logged in — transforms run within your Claude subscription
- **Notion export** is configured in Settings (⌘,) → Notion tab (integration token and parent page ID)

## Privacy & data

- Scratch buffers live in `~/Library/Application Support/Editan/` as plain Markdown — yours to grep, back up, or sync however you like
- Nothing leaves your Mac except what you explicitly trigger: LLM transforms (through your local `claude` CLI) and Notion export (Notion API)
- No analytics, no crash reporting, no auto-update phoning home

## Development

Requirements: Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```sh
brew install xcodegen
xcodegen generate                 # project.yml → Editan.xcodeproj
open Editan.xcodeproj
```

Build from the CLI:

```sh
xcodebuild -project Editan.xcodeproj -scheme Editan -configuration Debug build
```

`.xcodeproj` is not committed — `project.yml` is the source of truth. Re-run `xcodegen generate` after adding, removing, or moving source files.

### Architecture at a glance

```
Editan/Sources/
├── EditanApp.swift        # App entry: window, menu bar extra, settings, hotkey
├── Models/                # Buffer + BufferStore (persistence, commands)
├── Editor/                # NSTextView wrapper, Markdown highlighter
├── Preview/               # Markdown → HTML, WKWebView preview
├── Transforms/            # claude CLI subprocess, templates, Slack mrkdwn
├── Notion/                # Markdown → Notion blocks, page-create API
├── Utils/                 # editor access, global hotkey
└── Views/                 # split pane, sidebar, menus, sheets, settings
```

Built with [swift-markdown](https://github.com/swiftlang/swift-markdown) for parsing and [highlight.js](https://highlightjs.org/) for code highlighting.

## Roadmap

- [ ] Landing page (EN/JP)
- [ ] Mac App Store release
- [ ] Auto-open `.md` files generated by AI coding agents (Claude Code, Codex)
- [ ] Preview scroll sync
- [ ] Buffer drag-reorder, pinning, and search
- [ ] Diff view for transform results
- [ ] Additional LLM providers (e.g. `codex exec`)

## Contributing

Issues and pull requests are welcome! A few notes:

- Run `xcodegen generate` after any file add/remove/move
- **⌘C must always copy plain text** — that invariant is the soul of the app
- Editor changes must be verified with Japanese IME input (composition must never break)
- There is no test target yet; please verify by building and running the app

## License

[MIT](LICENSE)
