# Editan

macOS 用ステージングエディタ(SwiftUI + AppKit、XcodeGen 管理)。コンセプトは「書く → 変換する → コピーして他アプリに貼る」。README.md にロードマップあり。

## ビルド

```sh
xcodegen generate   # project.yml から .xcodeproj を生成(.xcodeproj は gitignore 済み)
xcodebuild -project Editan.xcodeproj -scheme Editan -configuration Debug build
```

ソースを追加・削除したら `xcodegen generate` を再実行すること。

## 構成

- `Editan/Sources/Models/` — `Buffer`(1ドキュメント)と `BufferStore`(一覧・選択・永続化。スクラッチは `~/Library/Application Support/Editan/` に自動保存)
- `Editan/Sources/Editor/PlainTextEditor.swift` — NSTextView ラッパー。`PlainTextView` が copy/cut をオーバーライドしてプレーンテキストコピーを保証(このアプリの核。壊さないこと)
- `Editan/Sources/Preview/` — swift-markdown で HTML 化し WKWebView に表示

## 設計上の約束

- コピーは常にプレーンテキスト。ペーストボードに RTF/HTML を書くのは明示的な「Copy as ...」コマンドのみ(Phase 2)
- スマート引用符・自動修正の類は常にオフ
- LLM 機能は API 課金ではなく CLI(`claude -p` / `codex exec`)のサブプロセス呼び出しで実装する方針(サブスク内で使うため)
- Swift 5 言語モード(SWIFT_VERSION=5.0)
