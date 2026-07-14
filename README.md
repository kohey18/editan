# Editan

「書く → 変換する → コピーして貼る」ための macOS 用ステージングエディタ。

Claude Code へのプロンプト、Gmail での本文、Slack への貼り付けなど、**最終的に他のアプリに貼るテキスト**を書く場所として使う。クラウド同期なし、Mac 専用。

![Editan のスクリーンショット。左にバッファ一覧、中央に Markdown シンタックスハイライト付きエディタ、右にプレビュー](docs/screenshot.png)

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

## 他の Mac にインストールする

### 方法 1: ソースからビルド(推奨)

```sh
# 前提: macOS 14+ / Xcode 16+(App Store から)/ Homebrew
xcode-select --install            # 未導入なら
brew install xcodegen
git clone git@github.com:kohey18/editan.git
cd editan
./Scripts/install.sh              # /Applications/Editan.app にインストールされる
```

### 方法 2: ビルド済み .app をコピー

ビルド済みの Mac から `/Applications/Editan.app` を AirDrop / USB 等で相手の `/Applications` にコピーする。

署名が ad-hoc(未公証)のため、初回起動でブロックされた場合は:

```sh
xattr -dr com.apple.quarantine /Applications/Editan.app
```

または Finder で右クリック →「開く」。

### 補足

- **LLM 変換(敬語化など)**を使うには、その Mac に Claude Code CLI(`claude`)がインストールされ、ログイン済みであること(変換はサブスク内で実行される)
- Notion 転記は設定(⌘,)→ Notion タブでトークンと親ページ ID を Mac ごとに設定する
- スクラッチバッファは `~/Library/Application Support/Editan/` に保存される(端末間同期はしない設計)

## ロードマップ

- [x] Phase 1: MVP(バッファ管理 / プレーンコピー保証 / MD プレビュー)
- [x] Phase 2: MD シンタックスハイライト / フォーマッタ / Copy for Slack / Copy as HTML
- [x] Phase 3: LLM 変換(敬語変換など、`claude -p` 経由でサブスク内利用)
- [x] Phase 4: Notion 転記 / グローバルホットキー(⌥⌘E)/ メニューバー常駐 / 選択時アクションバー / アプリアイコン
