# Third-party notices

Editan's own source is [MIT-licensed](LICENSE). Third-party components retain their respective licenses.

| Component | Version | Use | License / notices |
| --- | --- | --- | --- |
| [swift-markdown](https://github.com/swiftlang/swift-markdown) | 0.8.0 | Markdown parsing and formatting | [Apache 2.0 with Swift runtime exception](Editan/Resources/Licenses/swift-markdown-LICENSE.txt), [NOTICE](Editan/Resources/Licenses/swift-markdown-NOTICE.txt) |
| [swift-cmark](https://github.com/swiftlang/swift-cmark) | 0.8.0 | Underlying Markdown parser | [COPYING, including component notices](Editan/Resources/Licenses/swift-cmark-COPYING.txt) |
| [highlight.js](https://github.com/highlightjs/highlight.js) | 11.11.1 | Bundled preview syntax highlighting and themes | [BSD 3-Clause](Editan/Resources/highlight/LICENSE) |

License files under `Editan/Resources/` are included in app builds. Preserve them when redistributing binaries. Markdown dependencies are pinned in `project.yml`; highlight.js is vendored and does not load from a CDN.

[XcodeGen](https://github.com/yonaskolb/XcodeGen) and [Gitleaks](https://github.com/gitleaks/gitleaks) are development tools, not bundled application dependencies.

The landing page uses the existing project icon and an actual app capture derived from `docs/demo.gif`. Product names identify intended workflows; no affiliation with or endorsement by Apple, Anthropic, Slack, Google, or Notion is implied.
