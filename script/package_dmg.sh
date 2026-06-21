#!/usr/bin/env bash
set -euo pipefail

# 构建 release 通用二进制（arm64 + x86_64），打包成可分发的 DMG。
# 用法: ./script/package_dmg.sh [version]
# 例:   ./script/package_dmg.sh 0.0.100
#
# 版本方案：0.0.x 线性递增，每次改了功能就 +1（0.0.100 → 0.0.101 → ...）。

VERSION="${1:-0.0.100}"
APP_NAME="RightNow"
BUNDLE_ID="com.xifuduo.RightNow"
MIN_SYSTEM_VERSION="13.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
DMG_ROOT="$DIST_DIR/dmg_root"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"

# 通用二进制（arm64 + x86_64），Intel 与 Apple Silicon 都能运行。
# 需要完整 Xcode（提供 xcbuild）；纯 Command Line Tools 环境不可用。
echo "==> 构建 release 通用二进制 (arm64 + x86_64)"
swift build -c release --arch arm64 --arch x86_64
BUILD_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"

echo "==> 组装 $APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
# 复制依赖的资源 bundle（如有）。
find "$BUILD_DIR" -maxdepth 1 -name '*.bundle' -type d -exec cp -R {} "$APP_RESOURCES/" \;
# App 图标 + 菜单栏图标。
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
cp "$ROOT_DIR/Resources/MenuBarIcon.png" "$APP_RESOURCES/MenuBarIcon.png"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> ad-hoc 签名（让它在 Apple Silicon 上能启动）"
codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE" && echo "    签名校验通过"

echo "==> 制作 DMG"
rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_BUNDLE" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -fs HFS+ \
  -format UDZO \
  -ov \
  "$DMG_PATH" >/dev/null
rm -rf "$DMG_ROOT"

echo ""
echo "完成 ✅"
echo "  架构:   $(lipo -archs "$APP_BINARY" 2>/dev/null || echo '?')"
echo "  DMG:    $DMG_PATH"
echo "  大小:   $(du -h "$DMG_PATH" | cut -f1)"
