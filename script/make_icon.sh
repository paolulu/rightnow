#!/usr/bin/env bash
set -euo pipefail

# 由 script/AppIcon.swift 生成全套尺寸并合成 Resources/AppIcon.icns。
# 改了图标设计后重跑本脚本即可。

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
PNG="$TMP/AppIcon-1024.png"
ICONSET="$TMP/AppIcon.iconset"
OUT="$ROOT_DIR/Resources/AppIcon.icns"
trap 'rm -rf "$TMP"' EXIT

echo "==> 渲染 1024 源图"
swift "$ROOT_DIR/script/AppIcon.swift" "$PNG"

echo "==> 生成 iconset 各尺寸"
mkdir -p "$ICONSET"
sips -z 16 16   "$PNG" --out "$ICONSET/icon_16x16.png"      >/dev/null
sips -z 32 32   "$PNG" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 32 32   "$PNG" --out "$ICONSET/icon_32x32.png"      >/dev/null
sips -z 64 64   "$PNG" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 128 128 "$PNG" --out "$ICONSET/icon_128x128.png"    >/dev/null
sips -z 256 256 "$PNG" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$PNG" --out "$ICONSET/icon_256x256.png"    >/dev/null
sips -z 512 512 "$PNG" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$PNG" --out "$ICONSET/icon_512x512.png"    >/dev/null
cp "$PNG" "$ICONSET/icon_512x512@2x.png"

echo "==> 合成 .icns"
mkdir -p "$ROOT_DIR/Resources"
iconutil -c icns "$ICONSET" -o "$OUT"

echo "完成 ✅ -> Resources/AppIcon.icns ($(du -h "$OUT" | cut -f1))"
