#!/bin/zsh
# Release ビルドして /Applications にインストールする
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate
# Set EDITAN_TEAM_ID to your Apple Developer team ID to sign the local install with your
# Apple Development certificate, so TCC permissions survive rebuilds (ad-hoc signing is
# identified by the binary's hash and loses them every time). Without it, the build uses the
# project default (ad-hoc). CI and release.sh are unaffected: project.yml stays ad-hoc.
SIGN_ARGS=()
if [ -n "${EDITAN_TEAM_ID:-}" ]; then
  echo "note: signing with Apple Development (team $EDITAN_TEAM_ID)"
  SIGN_ARGS=(-allowProvisioningUpdates CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" DEVELOPMENT_TEAM="$EDITAN_TEAM_ID")
else
  echo "note: EDITAN_TEAM_ID is not set; installing an ad-hoc signed build"
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
