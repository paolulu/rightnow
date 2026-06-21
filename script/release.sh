#!/usr/bin/env bash
set -euo pipefail

# 一键发布：校验 → 打包通用 DMG → 提交 → 推送 → 建 GitHub Release → 同步 tag。
#
# 用法: ./script/release.sh <version> "<更新说明>"
# 例:   ./script/release.sh 0.0.101 "新增 xxx；修复 yyy"
#
# 版本方案：0.0.x 线性递增，每次改了功能就 +1。

APP_NAME="RightNow"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:-}"
NOTES="${2:-}"

if [[ -z "$VERSION" || -z "$NOTES" ]]; then
  echo "用法: ./script/release.sh <version> \"<更新说明>\"" >&2
  echo "例:   ./script/release.sh 0.0.101 \"新增 xxx；修复 yyy\"" >&2
  exit 2
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "✗ 版本号格式应为 主.次.修，例如 0.0.101（你给的是 '$VERSION'）" >&2
  exit 2
fi

TAG="v$VERSION"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME-$VERSION.dmg"

# 必须在 main 分支发布。
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "main" ]]; then
  echo "✗ 当前在 '$BRANCH' 分支，请先切到 main 再发布" >&2
  exit 1
fi

# 同一个版本号不能发两次。
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1 || gh release view "$TAG" >/dev/null 2>&1; then
  echo "✗ 版本 $TAG 已存在，请换一个版本号" >&2
  exit 1
fi

echo "==> [1/5] 构建通用 DMG（基于当前代码，含未提交改动）"
./script/package_dmg.sh "$VERSION"
[[ -f "$DMG_PATH" ]] || { echo "✗ 没找到 $DMG_PATH" >&2; exit 1; }

echo "==> [2/5] 提交代码"
if [[ -n "$(git status --porcelain)" ]]; then
  git status --short
  git add -A
  git commit -q -m "Release $TAG

$NOTES"
  echo "    已提交工作区改动"
else
  echo "    工作区干净，无需提交"
fi

echo "==> [3/5] 推送 main"
git push -q origin main

echo "==> [4/5] 创建 GitHub Release $TAG"
RELEASE_NOTES="## $APP_NAME $VERSION

$NOTES

---
### 下载与安装
下载 \`$APP_NAME-$VERSION.dmg\`，打开后把 **$APP_NAME.app 拖进 Applications**。

> 支持 **Apple Silicon 与 Intel** Mac（通用二进制），需 macOS 13+。

首次打开会提示\"无法验证开发者\"，放行一次即可：
**系统设置 → 隐私与安全性 → \"仍要打开\"**；或终端执行
\`xattr -dr com.apple.quarantine /Applications/$APP_NAME.app\`。

⚠️ 首次使用需在「系统设置 → 隐私与安全性 → 辅助功能」里勾选 $APP_NAME。"

gh release create "$TAG" "$DMG_PATH" \
  --target main \
  --title "$APP_NAME $VERSION" \
  --notes "$RELEASE_NOTES"

echo "==> [5/5] 同步 tag 到本地"
git fetch --tags -q || true
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1 || git tag "$TAG"

echo ""
echo "完成 ✅ 已发布 $TAG"
echo "  $(gh release view "$TAG" --json url --jq .url 2>/dev/null || echo "https://github.com/paolulu/rightnow/releases/tag/$TAG")"
