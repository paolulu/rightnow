# RightNow

macOS 菜单栏小工具：一键在任意输入框插入「当下时间」。

适合写日志、做记录、聊天时快速打时间戳，不用切输入法、不用手敲。

## 功能

- 🕘 **菜单栏常驻**：顶部状态栏显示 `Now HH:mm`，后台运行，Dock 无图标。
- ⌨️ **两种触发方式**
  - **组合键**：默认 `⌘⇧T`，可在面板里重新录制。
  - **字符序列**：依次按下一串字符即可触发（默认 `=n`，可改），输入的触发字符会被自动删除。适合不想记组合键的人。
- 🧩 **自定义时间格式**：基于 `DateFormatter` 模板，如 `yyyy-MM-dd HH:mm`，面板内提供常用 token 一键插入与实时预览。
- 🚀 **登录时启动**：开关即可（`SMAppService`）。

## 运行

需要 macOS 13+。当前用 SwiftPM 手工打包：

```bash
./script/build_and_run.sh
```

脚本会 `swift build`、打包成 `dist/RightNow.app` 并启动。

## 权限

插入文本与字符序列监听都依赖 **辅助功能（Accessibility）** 权限。首次运行会弹窗请求；若快捷键 / 序列无反应，请到
「系统设置 → 隐私与安全性 → 辅助功能」确认 RightNow 已勾选。

## 项目结构

```
Sources/
  RightNowCore/        纯逻辑（时间格式化），可单元测试
  RightNow/
    App/               入口 + AppDelegate（NSStatusItem 菜单栏）
    Stores/            AppState（状态、快捷键、序列触发、自启动）
    Views/             SettingsPanel 设置面板
    Services/          文本插入 / 序列监听 / 辅助功能 / 登录启动
```

详细的开发记录与设计取舍见 [CHANGELOG.md](CHANGELOG.md)。

## 依赖

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) —— 组合键录制。

## 已知事项

- 字符序列默认 `=n`，在正常文本中也可能误触（如 `x=n`）；可在设置里改成更少见的组合，如 `;now`。
- 单元测试当前使用 Swift Testing（`import Testing`），需完整 Xcode 工具链；纯 Command Line Tools 环境下 `swift test` 暂不可用。
