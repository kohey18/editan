#!/bin/zsh
# Release ビルドして /Applications にインストールする
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate
# Sign the local install with the Apple Development certificate (team 3U5Y9G26T3) when it
# exists, so TCC permissions survive rebuilds (ad-hoc signing is identified by the binary's
# hash and loses them every time). Falls back to the project default (ad-hoc) otherwise.
# CI and release.sh are unaffected: project.yml stays ad-hoc.
SIGN_ARGS=()
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Development"; then
  SIGN_ARGS=(-allowProvisioningUpdates CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" DEVELOPMENT_TEAM=3U5Y9G26T3)
else
  echo "note: no Apple Development identity; installing an ad-hoc signed build"
fi
xcodebuild -project Editan.xcodeproj -scheme Editan -configuration Release \
  -derivedDataPath build/DerivedData "${SIGN_ARGS[@]}" build

APP=build/DerivedData/Build/Products/Release/Editan.app
if [ ! -d "$APP" ]; then
  echo "ビルド失敗: $APP がありません" >&2
  exit 1
fi

pkill -x Editan 2>/dev/null || true
sleep 1
rm -rf /Applications/Editan.app
ditto "$APP" /Applications/Editan.app
echo "✅ /Applications/Editan.app にインストールしました"
