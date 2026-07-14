# Editan

「書く → 変換する → コピーして貼る」ための macOS 用ステージングエディタ。

Claude Code へのプロンプト、Gmail での本文、Slack への貼り付けなど、**最終的に他のアプリに貼るテキスト**を書く場所として使う。クラウド同期なし、Mac 専用。

## 特徴

- コピーは常にプレーンテキスト(リッチテキストが混入しない)
- スクラッチバッファ中心(保存操作なしで自動永続化)+ .md ファイルも開ける
- Markdown の分割ペインプレビュー
- スマート引用符・自動修正などのお節介は全オフ

## 開発

必要なもの: Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```sh
brew install xcodegen
xcodegen generate
open Editan.xcodeproj
```

CLI でビルドする場合:

```sh
xcodebuild -project Editan.xcodeproj -scheme Editan -configuration Debug build
```

Release ビルドを `/Applications` にインストール:

```sh
./Scripts/install.sh
```

`.xcodeproj` はコミットしない。`project.yml` が正。

## ロードマップ

- [x] Phase 1: MVP(バッファ管理 / プレーンコピー保証 / MD プレビュー)
- [x] Phase 2: MD シンタックスハイライト / フォーマッタ / Copy for Slack / Copy as HTML
- [x] Phase 3: LLM 変換(敬語変換など、`claude -p` 経由でサブスク内利用)
- [x] Phase 4: Notion 転記 / グローバルホットキー(⌥⌘E)/ メニューバー常駐 / 選択時アクションバー / アプリアイコン
