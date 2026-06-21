#!/usr/bin/env bash
set -euo pipefail

# 从 Resources/AppIconSource.png（1024×1024 主图源）生成全套尺寸并合成 Resources/AppIcon.icns。
# 换图标：替换 Resources/AppIconSource.png（保持 1024×1024）后重跑本脚本即可。

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT_DIR/Resources/AppIconSource.png"
TMP="$(mktemp -d)"
ICONSET="$TMP/AppIcon.iconset"
OUT="$ROOT_DIR/Resources/AppIcon.icns"
trap 'rm -rf "$TMP"' EXIT

[[ -f "$SRC" ]] || { echo "✗ 缺少源图 $SRC（需 1024×1024 PNG）" >&2; exit 1; }

echo "==> 生成 iconset 各尺寸"
mkdir -p "$ICONSET"
sips -z 16 16   "$SRC" --out "$ICONSET/icon_16x16.png"      >/dev/null
sips -z 32 32   "$SRC" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 32 32   "$SRC" --out "$ICONSET/icon_32x32.png"      >/dev/null
sips -z 64 64   "$SRC" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 128 128 "$SRC" --out "$ICONSET/icon_128x128.png"    >/dev/null
sips -z 256 256 "$SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$SRC" --out "$ICONSET/icon_256x256.png"    >/dev/null
sips -z 512 512 "$SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$SRC" --out "$ICONSET/icon_512x512.png"    >/dev/null
cp "$SRC" "$ICONSET/icon_512x512@2x.png"

echo "==> 合成 .icns"
mkdir -p "$ROOT_DIR/Resources"
iconutil -c icns "$ICONSET" -o "$OUT"

echo "完成 ✅ -> Resources/AppIcon.icns ($(du -h "$OUT" | cut -f1))"
