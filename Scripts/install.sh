#!/bin/zsh
# Release ビルドして /Applications にインストールする
set -e
cd "$(dirname "$0")/.."

xcodegen generate
xcodebuild -project Editan.xcodeproj -scheme Editan -configuration Release \
  -derivedDataPath build/DerivedData build | grep -E "error:|warning: .*deprecated|BUILD" || true

APP=build/DerivedData/Build/Products/Release/Editan.app
if [ ! -d "$APP" ]; then
  echo "ビルド失敗: $APP がありません" >&2
  exit 1
fi

osascript -e 'tell application "Editan" to quit' 2>/dev/null || true
sleep 1
rm -rf /Applications/Editan.app
ditto "$APP" /Applications/Editan.app
echo "✅ /Applications/Editan.app にインストールしました"
