#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "==> Building MacTab in Release mode..."
swift build -c release

APP_NAME="MacTab"
BUNDLE_DIR="$DIR/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Packaging $APP_NAME.app..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$DIR/.build/release/MacTab" "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp "$DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Ad-hoc code sign for macOS local execution with stable designated requirement
# (Important: prevents macOS TCC permissions from getting lost/broken on rebuild)
codesign --force --deep -s - --requirements '=designated => identifier "com.mactab.app"' "$BUNDLE_DIR"

echo "==> Successfully created $BUNDLE_DIR"
echo "You can now run it directly: open $BUNDLE_DIR"
