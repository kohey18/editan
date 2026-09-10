# Contributing to Editan

Small, focused contributions are welcome: bug reports, documentation, accessibility improvements, and careful testing of Japanese input all make a difference. English and Japanese are both welcome in issues and pull requests.

For a larger feature, open an issue describing the problem and a concrete example first. Keep PRs focused on one behavior. Do not include personal drafts, credentials, signing material, or machine-specific paths in screenshots or logs.

## Build and test

Use macOS 14+, full Xcode 26+, and XcodeGen (`brew install xcodegen`). `project.yml` is the source of truth; run `xcodegen generate` after adding, moving, or removing source files.

```sh
xcodegen generate
xcodebuild -project Editan.xcodeproj -scheme Editan \
  -configuration Debug -derivedDataPath build/DerivedData build
xcodebuild -project Editan.xcodeproj -scheme EditanSecurityTests \
  -destination 'platform=macOS' -derivedDataPath build/DerivedData test
```

The security test target compiles the relevant components in isolation. It does not launch Editan, call Claude or Notion, or read your real credentials. Keep it that way.

For website changes:

```sh
python3 Scripts/build_site.py
node --check docs/assets/site.js
python3 -m http.server 4173 --bind 127.0.0.1 --directory build/pages
```

Check English and Japanese pages, narrow screens, keyboard navigation, reduced motion, and clipboard failure messages. Keep both READMEs and site languages aligned when changing a feature claim. See [website maintenance](docs/website.md).

## Design invariants

- Standard **⌘C and cut must always produce plain text**. HTML and rich text belong only in explicit export commands.
- Do not replace text or apply syntax attributes during Japanese IME composition. Editor changes need hands-on testing of composition, conversion, selection, and undo.
- Smart quotes and autocorrect stay off.
- Text replacements must participate in Undo.
- Markdown-to-HTML must pass through `SafeHTMLFormatter`. Preserve the preview CSP and its navigation allowlist.
- Claude transformations are subprocess calls for text only. Do not restore tool access, MCP servers, hooks, or persistent sessions.
- Credentials belong in Keychain. Never add a preference-based fallback; migration must preserve the old value if Keychain access fails.

## Security and dependencies

Read [SECURITY.md](SECURITY.md) before reporting a vulnerability. Do not attach exploitable details or credentials to public issues.

```sh
brew install gitleaks
gitleaks git . --log-opts='--all' --redact
```

Markdown and cmark versions are pinned in `project.yml`. Upgrade them deliberately, review upstream changes and advisories, and run the regression tests. Preserve bundled dependency license notices. Actions use pinned commit SHAs; Dependabot proposes updates.

Write commit messages in English. Before committing, inspect `git diff --cached`, especially generated images and logs. Use a GitHub noreply address if you do not want your email address in public history.

By submitting a contribution, you agree that it may be distributed under this project's [MIT license](LICENSE). Third-party components retain their own licenses.
