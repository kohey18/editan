# Public-release review — 2026-09-10

## Conclusion

No credentials were detected in the reviewed Git history. Several application and release-preparation issues were fixed on the public-release preparation branch. This is a bounded source/history review, not a security certification or a claim that the application has no vulnerabilities.

**Public visibility has not been changed.** The owner approved retaining the existing author-email history. The requested generated artwork will use the Images API with GPT Image 2.5; generation is pending a configured API key. Keep this report separate from the landing-page deployment artifact.

## Scope and evidence

Baseline: `cb0c9cab123d5970c1c962364907dc1cf0cb7faf`, freshly fetched `origin/main`. The working tree was initially clean. One remote branch (`main`), no remote tags, and 25 reachable commits were present at the start.

- Gitleaks 8.30.1 scanned all available refs with `gitleaks git . --log-opts='--all' --redact`: no findings. The diff scanner reported 24 content-bearing commits; the full history has 25.
- A second scan covered all 97 unique historical text blobs, including deleted/previous versions and initial content: no findings.
- Commit messages and author/committer metadata were scanned separately: no secret findings.
- Reviewed the two historical documentation screenshots, the app icon, and representative frames of the 7-frame demo. No obvious tokens or private documents were visible; the screenshots contain sample release notes. Automated secret scanning does not establish the absence of sensitive content in binary images.
- Reviewed credentials, subprocess invocation, Markdown rendering/CSP/navigation, clipboard export, file persistence, Notion network calls, install behavior, repository configuration, and dependency notices.
- OSV queries for `highlight.js` 11.11.1 (npm), `swift-markdown` 0.8.0, and `swift-cmark` 0.8.0 (SwiftURL) returned no matching advisories on the review date. This depends on database/package coverage, not a complete audit of dependencies. [OSV API documentation](https://google.github.io/osv.dev/api/).

Local scan and build logs live in ignored `build/public-audit/`. They are not included in the website or committed as public evidence. The scan scope is the fetched refs and available Git objects; it does not cover deleted GitHub refs, external forks, inaccessible server-side objects, release assets in another repository, or external account configuration.

## Findings and changes

| Area | Finding | Resolution |
| --- | --- | --- |
| Credentials | Notion token stored in UserDefaults | macOS Keychain storage with explicit save/delete and legacy migration. A failed Keychain read/write does not delete the old preference. |
| Agent capabilities | Text transforms inherited Claude tool/configuration capabilities | Disable built-in/MCP tools, hooks, slash commands, normal settings sources, and session persistence. Use safe mode to skip ordinary CLAUDE.md/memory/plugins, a text-only system prompt, and direct process arguments. |
| Process availability | Sequential stdout/stderr reads could block on a full error pipe | Drain both concurrently; tested with 128 KiB of stderr. |
| Install correctness | Failed `xcodebuild` was suppressed and could install a stale build | `set -euo pipefail`; do not suppress build failure. |
| Preview | Existing formatter/CSP/navigation restrictions already block active HTML and remote resources | Preserve the defenses and add regression coverage. Preview external images were not a new network leak. Exported HTML has a separate receiving-app policy. |
| Privacy claims | “Everything stays on your Mac” / unconditional “no extra billing” were too broad | Describe optional outbound transfers, CLI-dependent authentication/billing, plaintext drafts, and clipboard boundaries accurately. |
| Dependencies | Open version ranges could select a newer incompatible toolchain | Pin Markdown and cmark at the resolved/tested 0.8.0; document Xcode 26+ / Swift tools 6.2. |
| Redistribution | Swift dependency license notices were not included explicitly in app resources | Add upstream license/notice files and a third-party inventory. |
| Future leakage | Build output and credentials lacked explicit repository ignore rules | Add ignored build, environment, signing-key and certificate patterns. Add history scanning to CI. |
| Website publication | Publishing all of `docs/` would expose unrelated notes | Stage a fixed allowlist. Deploy only public `main`, using scoped permissions and pinned action commits. |

## Owner decisions before visibility change

On 2026-09-10, the owner explicitly approved retaining the existing Git history, including the personal Gmail address in author/committer metadata. No existing commits have been rewritten. New preparation commits use the owner's GitHub noreply address.

The owner also requested API-based image generation. The planned model is `gpt-image-2.5-sunburst`; generation requires a locally configured API key. Repository visibility remains private while preparation is completed.

The repository remains MIT-licensed. Existing AI-assisted-development instructions and configuration will also become visible as source files. Confirm the intended public surface after any concurrent work is merged.

## Validation

- All application Swift sources compiled and linked successfully in an isolated SwiftPM validation harness against Markdown/cmark 0.8.0.
- **11 security regression tests passed**: raw HTML/code escaping, unsafe schemes, preview CSP, four credential migration paths, restricted CLI arguments, large stderr, and subprocess failure propagation. Migration tests use injected storage operations and disposable preferences; they do not exercise the owner's actual Keychain token.
- XcodeGen project generation succeeded with the standalone `EditanSecurityTests` target. A temporary ad-hoc app bundle containing the SwiftPM-built executable launched successfully and was then closed; the installed app was not replaced.
- The local Xcode 26.5 app build stalled before compilation at `CreateBuildDescription` / clang tool information discovery; that run was stopped. The SwiftPM validation is not a substitute for a successful Xcode app-bundle build.
- The static-site staging/link/metadata checks, JavaScript syntax check, shell syntax check, and `git diff --check` passed.
- Browser connection discovery returned no available browser. Responsive/interactive visual QA and native settings/Keychain end-to-end behavior are not claimed as verified.
- Real Claude transformations and Notion exports were not invoked: this review did not send user drafts, spend provider quota, or create Notion pages.

The normal Xcode app build and all 11 Xcode tests passed in [GitHub Actions run 34444768208](https://github.com/kohey18/editan/actions/runs/34444768208) for commit `c79b99d`. This verifies the app-bundle build independently of the local Xcode environment issue.

## Remaining boundaries

- Drafts are plaintext and the app is not App Sandbox-isolated. The clipboard may be read or synced by other software/system features.
- Ad-hoc source builds are not notarized; actual signed distribution requires a separate release process.
- Keychain migration is lazy. Older backups or preference domains from a previous bundle identifier are not erased automatically.
- Claude is a trusted local executable, not an OS-sandboxed subprocess. Managed/provider policies and server retention remain outside Editan's control. There is no transform timeout yet.
- Large/pathological documents can affect performance; no strict resource bounds or fuzz campaign were part of this review.
- Some file persistence paths still suppress write errors; disk-full/permission-failure data-loss handling merits follow-up before stronger reliability claims.
- Notion export can partially succeed before later block-upload failure; retrying may duplicate a page.
- Existing Swift 6 actor-isolation warnings in the editor remain warnings under the app's Swift 5 language mode.

The separately added `Scripts/release.sh` and `docs/distribution.md` appeared during this session as concurrent work. They are preserved but are outside this change set and this audit's completed verification scope. Review them before merging them into a public source release.
