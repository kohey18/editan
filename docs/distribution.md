# Editan の一般配布

Mac App Store 外で、Developer ID 署名と Apple の公証を付けた DMG を公開します。
対応 OS は macOS 14 以降、配布ビルドは Apple Silicon / Intel の Universal Binary です。

## 初回のみ必要な Apple の設定

1. [Apple Developer Program](https://developer.apple.com/programs/enroll/) に加入します(個人登録の場合、法人情報や D-U-N-S 番号は不要)。
   本人確認・契約への同意・年会費の支払いはアカウント所有者が行います。
2. Xcode → Settings → Accounts → 対象アカウント/チーム → Manage Certificates から
   **Developer ID Application** 証明書を作成します(発行には Account Holder 権限が必要)。
   既存証明書が別の Mac にある場合は、秘密鍵とセットで移行できます。
   `Apple Development` や `Apple Distribution` はこの配布方法の署名には使いません。
3. https://account.apple.com/ のサインインとセキュリティからアプリ用パスワードを発行し、
   次を**ご自身のターミナル**で実行します。パスワードは対話プロンプトに入力し、チャットや Git に保存しません。

```sh
xcrun notarytool store-credentials macos-notary \
  --apple-id 'YOUR_APPLE_ACCOUNT_EMAIL' \
  --team-id 'YOUR_TEAM_ID'
```

`Scripts/release.sh` はメンテナのチーム ID を既定値として使います(`APPLE_TEAM_ID` /
`DEVELOPER_ID_APPLICATION` / `NOTARY_PROFILE` の環境変数で上書き可能)。
ローカルビルドは ad-hoc 署名、配布ビルドは Developer ID Application 署名を使用します。
この配布方法では App Store Connect のアプリ登録や TestFlight 招待は不要です。

## ビルド・公証

```sh
# 有効な証明書名を確認(秘密鍵は表示しません)
security find-identity -v -p codesigning

export APPLE_TEAM_ID='YOUR_TEAM_ID'
export DEVELOPER_ID_APPLICATION='Developer ID Application: Your Name (YOUR_TEAM_ID)'
export NOTARY_PROFILE='macos-notary'
./Scripts/release.sh --check
./Scripts/release.sh 0.1.0 1
```

スクリプトは独立した出力ディレクトリに新規ビルドし、次を実施します。

1. Release / Universal ビルド、Developer ID 署名、Hardened Runtime とタイムスタンプを設定。
2. アプリを公証し、Accepted を確認してチケットを添付。
3. Applications へのリンクを含む DMG を作成・署名・公証してチケットを添付。
4. 署名、両 CPU アーキテクチャ、チケット、Gatekeeper の検証後に SHA-256 を出力。

出力先は `build/distribution/Editan-VERSION.XXXXXX/`。
署名や公証に失敗した出力物は公開しないでください。公証結果/失敗ログも同じディレクトリに保存されます。
公証の待機が中断された場合は、結果 JSON の submission ID を使って `xcrun notarytool info` / `log` で確認します。

証明書なしでコンパイルのみ検証する場合:

```sh
./Scripts/release.sh --build-only 0.1.0 1
```

これはローカル用の ad-hoc 署名アプリだけを作り、配布用 DMG は作りません。
既存の install.sh と生成プロジェクトの出力先を分けており、/Applications の常用版を置き換えません。

## 公開前の確認

- 別の Mac/新規ユーザーで、ブラウザから DMG をダウンロードして Applications にコピーし起動。
- 開発元未確認の回避操作や `xattr` による隔離属性解除が不要なことを確認。
- 日本語 IME、保存、コピー、プレビューを確認。Claude CLI と Notion 連携は任意で、利用者自身の設定が必要です。
- DMG と `.dmg.sha256` を [editan-releases](https://github.com/kohey18/editan-releases) の GitHub Release にアップロード。
- ダウンロードリンクがログアウト状態でも使えること、公開 DMG の SHA-256 が検証済みファイルと一致することを確認。

## Apple 公式資料

- [Developer Program 加入](https://developer.apple.com/programs/enroll/)
- [Developer ID 証明書](https://developer.apple.com/help/account/certificates/create-developer-id-certificates)
- [macOS の配布方法](https://developer.apple.com/macos/distribution/)
- [公証ワークフロー](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)
