# Editan

macOS 用ステージングエディタ(SwiftUI + AppKit、XcodeGen 管理、Swift 5 言語モード)。
コンセプトは「書く → 変換する → コピーして他アプリに貼る」。貼り付け先は Claude Code / Gmail / Slack / Notion。
クラウド同期なし・Mac 専用・個人利用(ad-hoc 署名、App Store 非対応で OK)。

## ビルド・実行・インストール

```sh
xcodegen generate    # project.yml → .xcodeproj(.xcodeproj は gitignore 済み)
xcodebuild -project Editan.xcodeproj -scheme Editan -configuration Debug -derivedDataPath build/DerivedData build
./Scripts/install.sh # Release ビルドを /Applications にインストール
```

- **ソースファイルを追加・削除・移動したら必ず `xcodegen generate` を再実行**(忘れるとビルドに含まれない)
- 動作確認の再起動: `pkill -x Editan; open build/DerivedData/Build/Products/Debug/Editan.app`
- ビルド確認は `xcodebuild ... 2>&1 | grep -E "error:|BUILD"` で十分
- テストターゲットは未整備。変更後は必ずビルド + アプリ起動確認まで行い、ユーザーに UI 動作確認を依頼する
- 機能追加やバグ修正が動いたら、フェーズ・機能単位でコミットして push する(このリポジトリの運用)

## アーキテクチャ

```
Editan/Sources/
├── EditanApp.swift           # App エントリ。Window + MenuBarExtra + Settings シーン、ホットキー登録
├── Models/
│   ├── Buffer.swift          # 1ドキュメント。fileURL == nil ならスクラッチ。title は先頭行から導出
│   └── BufferStore.swift     # 一覧・選択・永続化・コピー/整形/Notion コマンドの実体(@MainActor)
├── Editor/
│   ├── PlainTextEditor.swift # NSTextView ラッパー(PlainTextView)。プレーンコピー保証・リスト継続改行・
│   │                         # 選択時アクションバー(整形/敬語化)・IME ガード
│   └── MarkdownHighlighter.swift # swift-markdown の SourceRange → NSRange 変換(SourceMap)+ 全文ハイライト
├── Preview/
│   ├── MarkdownRenderer.swift # MD → HTML(SoftBreak → <br> 書き換え済み)。body() はリッチコピーにも使う
│   └── MarkdownPreview.swift  # WKWebView。250ms デバウンス、スクロール位置復元、リンクはブラウザへ
├── Transforms/
│   ├── ClaudeCLI.swift       # claude -p のサブプロセス実行。パスは既知候補 + zsh -lc で解決しキャッシュ
│   ├── TransformStore.swift  # テンプレート管理 + 変換セッション(実行→シート→置換/コピー)
│   ├── TransformTemplate.swift # 既定テンプレート(敬語/カジュアル/校正/要約)
│   └── SlackMarkdown.swift   # MD → Slack 貼り付け用テキスト(mrkdwn 風)
├── Notion/
│   ├── NotionBlocks.swift    # MD → Notion ブロック JSON(rich_text の annotations 対応)
│   └── NotionClient.swift    # ページ作成 API。100 ブロック超は分割追記
├── Utils/
│   ├── EditorAccess.swift    # ビュー階層から PlainTextView を探す / Undo 対応の全文置換
│   └── AppActivator.swift    # ⌥⌘E グローバルホットキー(Carbon)+ アプリ前面化
└── Views/                    # ContentView(分割ペイン)/ Sidebar / AppCommands(メニュー)/
                              # 変換シート / 設定(変換・Notion タブ)/ ショートカットヘルプ
```

データの流れ: メニュー(AppCommands)→ BufferStore/TransformStore → `EditorAccess.currentTextView()` で
NSTextView を取得して操作。エディタ→モデルは NSTextViewDelegate.textDidChange → Binding 経由。

永続化: スクラッチは `~/Library/Application Support/Editan/Buffers/<uuid>.md` + `index.json`
(500ms デバウンス自動保存)。変換テンプレートは同 `templates.json`。Notion トークンは UserDefaults。

## 破ってはいけない設計原則

1. **⌘C は常にプレーンテキスト**(PlainTextView の copy/cut オーバーライド)。ペーストボードに
   RTF/HTML を書いてよいのは明示的な「〜としてコピー」コマンドのみ
2. スマート引用符・自動修正の類は常にオフ
3. LLM は API 課金ではなく CLI(`claude -p`)のサブプロセス。サブスク内で使うための要件
4. **IME(日本語入力)を壊さない**: `hasMarkedText()` 中は textView.string の差し替え・属性適用・
   insertNewline のカスタム処理をすべてスキップする。エディタ挙動を触ったら必ず日本語入力で確認を依頼
5. エディタのテキスト置換は Undo に載せる: `shouldChangeText(in:)` → `textStorage.replaceCharacters`
   → `didChangeText()` の 3 点セット(EditorAccess.replaceAllText 参照)

## ハマりどころ(過去に踏んだもの)

- ペーストボードに複数フレーバーを載せるときは `NSPasteboardItem` + `writeObjects`。
  `clearContents` 後に `setString` を型ごとに呼ぶ方式は 2 つ目が載らない
- swift-markdown の SourceLocation.column は **UTF-8 バイト単位**。NSRange(UTF-16)への変換は
  MarkdownHighlighter.SourceMap を必ず経由する(日本語だとズレる)
- Swift 5 言語モードでも @MainActor 隔離は強制される。DispatchQueue/通知クロージャからは
  `MainActor.assumeIsolated { ... }` で包む(既存コードにパターンあり)
- リスト行間・改行のプレビュー挙動は意図的: SoftBreak → `<br>`、`li > p { margin: 0 }`
- Markdown 整形(⇧⌘F)は `Document(parsing:).format()` によるラウンドトリップ。リスト記号などは
  swift-markdown 標準の流儀に正規化される
- NSTextView の layoutManager プロパティに触ると TextKit1 に降格するので触らない
  (座標が要るときは `firstRect(forCharacterRange:)` を使う。選択バーの実装参照)

## ユーザー(kohey)の好み・運用

- UI 文言・コミットメッセージ・応答はすべて日本語
- 体験の細部(フォーカス位置、行間、改行挙動)へのフィードバックが多い。エディタの手触りを最優先
- 変更したら Debug ビルドで再起動して即座に触れる状態にして報告する。常用版の更新は install.sh
- ⌥ などの記号キーの名前は自明ではない(ヘルプに凡例を入れてある)

## バックログ(未実装のアイデア)

- プレビューのスクロール同期 / バッファのドラッグ並べ替え・ピン留め・検索
- 変換結果の diff 表示 / GPT(codex exec)プロバイダ対応
- Notion トークンの Keychain 移行 / 配布するなら Developer ID 署名 + 公証
