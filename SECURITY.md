# Security policy

Editan is early-stage desktop software. Security fixes target the current `main` branch; older snapshots do not have a separate maintenance policy.

## Reporting a vulnerability

If GitHub shows **Security → Report a vulnerability**, use that private reporting channel. Include the commit, macOS version, minimal reproduction with synthetic data, expected behavior, and impact.

If private reporting is unavailable, open an issue asking the maintainer for a private contact channel **without the vulnerability details**. Do not post tokens, private drafts, exploit payloads, or unredacted logs in public issues. There is no guaranteed response SLA or bug bounty.

## Data and trust boundaries

Editan is a native, non-App-Sandbox macOS app. It can read and write files as the current user. Local storage is not a protection boundary against malware or another process running as you.

- Scratch drafts and templates are ordinary, unencrypted files under `~/Library/Application Support/Editan/`. Existing files stay at their original paths. Use your normal disk encryption and backup policy.
- Standard copy/cut writes plain text. Explicit rich-text export writes HTML plus plain text. The clipboard is shared with other applications and may be handled by system clipboard features or clipboard managers.
- Notion tokens use the macOS login Keychain, with service `io.github.kohey18.editan.notion` and account `integration-token`. The parent page ID remains in preferences.
- A legacy `notionToken` preference migrates on Notion settings access or export. It is removed only after a successful Keychain operation. Failed migration leaves the old credential in place and does not export it. Old backups and earlier bundle-ID preference domains are not purged automatically.
- Rebuilding an ad-hoc signed app may prompt for Keychain access again. There is no plaintext fallback when Keychain is locked or access is denied.

## Markdown preview and rich-text export

`SafeHTMLFormatter` escapes text, code, raw HTML, and attributes and restricts URL schemes. The preview's Content Security Policy blocks network resources, and navigation only opens user-clicked `http`, `https`, or `mailto` links in external apps. Highlight.js and its themes are bundled locally.

Preview JavaScript is used for syntax highlighting and code-copy buttons; it is not an environment for running scripts embedded in Markdown. Keep the formatter, CSP, and navigation checks together when changing this code.

The exported HTML body can contain remote image URLs. A receiving email or document application may load them under its own policy. The preview's CSP does not follow copied HTML into other apps. Large or pathological Markdown, image data, or code blocks may consume substantial memory/CPU; no strict document-size limit is imposed.

## Claude transforms

Transforms send the selection or full draft through the installed Claude Code CLI. The text is not processed entirely on-device. Authentication, provider endpoints, managed organization policy, usage limits, and billing belong to the user's CLI configuration.

The app passes text through stdin and supplies arguments directly to `Process`; it does not interpolate draft content into a shell command. A login shell is used only to locate the `claude` executable if known paths fail.

Invocation explicitly uses:

- `--safe-mode` to skip ordinary CLAUDE.md, memory, plugin, and other customization loading while retaining authentication
- `--tools ""` and `--disallowedTools "mcp__*"`
- `--strict-mcp-config` with an empty `mcpServers` configuration
- `--disable-slash-commands` and `--settings '{"disableAllHooks":true}'`
- `--setting-sources ""`, a text-transformation system prompt, and `--no-session-persistence`

Use a recent CLI that supports these flags; unsupported flags should fail rather than retry with weaker restrictions. These options reduce the agent's capabilities, **not the operating-system permissions of the CLI executable**. Use a trusted installation. They do not guarantee that the CLI/provider produces no diagnostics or retains no server-side data. Managed policy may still apply, including administrator-defined hooks that a command-line setting cannot disable. Stdout and stderr are drained concurrently; there is not yet a transform timeout/cancellation feature.

The flags follow the [Claude Code CLI reference](https://code.claude.com/docs/en/cli-usage).

## Notion export

An explicit export sends the current buffer to `https://api.notion.com`, authenticated with the user's integration token. Grant the integration only the pages and capabilities you need. Export can partially succeed before a later block-upload failure; retrying can create another page. Editan does not store Notion response logs intentionally.

## Distribution and website

Source builds use ad-hoc signing and Hardened Runtime, without notarization or App Sandbox. Do not treat an arbitrary shared `.app` as a verified release.

The GitHub Pages site contains static files and no analytics, remote fonts, accounts, or backend. Its clipboard examples operate locally. GitHub operates the hosting and may process ordinary web request data under its own policies. The publish workflow stages a fixed file allowlist; internal Markdown notes, source code, and local build logs are not part of the website artifact.
