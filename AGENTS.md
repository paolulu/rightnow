# AGENTS.md — RightNow 项目协作规则

供任何 AI / 新会话快速上手本项目。**动手前请先读完本文件。**

## 项目是什么

RightNow：macOS 菜单栏小工具，按全局快捷键 / 字符序列在任意输入框插入「当下时间」。

- SwiftPM 项目，macOS 13+，Swift Tools 6.1（**Swift 6 严格并发**）。
- 后台菜单栏应用（`LSUIElement=true`）：无主窗口、Dock 无图标，UI 在菜单栏 popover 里。
- Bundle ID：`com.xifuduo.RightNow`。

## 架构

- `Sources/RightNowCore/` — 纯逻辑（`TimestampFormatter`），可单元测试，不依赖 UI。
- `Sources/RightNow/` — App 本体：
  - `App/RightNowApp.swift` 入口（空 `Settings` scene）+ `App/AppDelegate.swift`（`NSStatusItem` 菜单栏核心，每秒刷新标题，点击弹 `NSPopover`）
  - `Stores/AppState.swift` — 状态、快捷键注册、序列触发接线、插入逻辑、自启动
  - `Views/SettingsPanel.swift` — 设置面板 UI
  - `Services/` — `TextInsertionService`（剪贴板 + 合成 ⌘V 插入）/ `SequenceTriggerService`（全局键盘序列监听）/ `AccessibilityPermission` / `LaunchAtLoginService`
  - `Models/ShortcutNames.swift` — KeyboardShortcuts 快捷键名

## 两种触发方式（都依赖辅助功能权限）

1. **组合键**：`KeyboardShortcuts` 库，默认 ⌘⇧T。
2. **字符序列**：`SequenceTriggerService` 用 `NSEvent` 全局监听，依次按字符触发（默认 `=n`），命中后自动退格删除已输入的触发字符。

## 构建 / 运行

- `./script/build_and_run.sh` — 开发用：构建 + 打包 `dist/RightNow.app` + 启动。启动后看**菜单栏右上角**，不是 Dock。
- `./script/package_dmg.sh <version>` — 出可分发 DMG（**通用二进制 arm64 + x86_64**）。
- 通用二进制需要**完整 Xcode**（提供 xcbuild）；若报许可错误，先 `sudo xcodebuild -license accept`。

## 发布新版本 ⚠️ 重要

- **版本方案**：`0.0.x` 线性递增，每改一次功能 +1（如 0.0.101 → 0.0.102）。
- **一条命令发布**：
  ```bash
  ./script/release.sh <version> "<更新说明>"
  ```
  流程：校验 → 构建通用 DMG → 提交 → 推送 → 建 GitHub Release → 同步 tag。
- **不要手动建 Release**，统一走 `release.sh`（内置版本号格式 / 必须在 main / 版本查重 防呆）。
- 分发是**免费、未公证**的：app 仅 ad-hoc 签名，用户首次打开需手动放行 Gatekeeper。**没有 Apple Developer 账号**，不要假设能公证或上架 App Store。

## 图标

- 程序化生成：改 `script/AppIcon.swift`（CoreGraphics 绘制）→ 跑 `./script/make_icon.sh` → 生成 `Resources/AppIcon.icns`。
- 两个打包脚本会自动把 icns 拷进 app 并在 Info.plist 设 `CFBundleIconFile`。

## 代码约定 / 坑

- **Swift 6 严格并发**：UI / 状态相关类型用 `@MainActor`；`KeyboardShortcuts` 用 `@preconcurrency import`。
- 文本插入与序列监听都需 **辅助功能（Accessibility）权限**。`TextInsertionService` 给合成事件打了 `eventSourceUserData` 标记，避免序列监听把自己发的退格 / ⌘V 当成用户输入——改这两处时务必保留该机制。
- 单元测试用 **Swift Testing**（`import Testing`），`swift test` 需完整 Xcode 工具链。

## 仓库卫生

- **不提交到 GitHub**（已 gitignore，仅本地）：`CHANGELOG.md`、`design_handoff_timestamp/`、`.codex/`、`dist/`、`.build/`。
- **保留** `Package.resolved`（锁依赖版本，保证构建一致）。
- 提交 / 推送由发布流程（`release.sh`）或用户明确要求时进行，不要擅自推送无关改动。

## 链接

- 仓库：https://github.com/paolulu/rightnow
- Releases：https://github.com/paolulu/rightnow/releases
