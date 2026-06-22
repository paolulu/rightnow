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

## 下载安装

到 [Releases](https://github.com/paolulu/rightnow/releases) 下载最新的 `RightNow-x.y.z.dmg`，打开后把 **RightNow.app 拖进 Applications**。

> 支持 **Apple Silicon 与 Intel** Mac（通用二进制），需要 macOS 13+。

### 首次打开要手动放行一次

这个 app 还没做 Apple 公证（notarization），所以首次打开会被系统拦下来提示"无法验证开发者"。放行一次即可，之后正常：

- **方式一（推荐）**：双击打开被拦后，去 **系统设置 → 隐私与安全性**，下拉找到 RightNow 那条，点 **"仍要打开"**。
- **方式二（终端）**：执行一次
  ```bash
  xattr -dr com.apple.quarantine /Applications/RightNow.app
  ```

放行后，**菜单栏右上角**会出现 `Now HH:mm`（这是个后台菜单栏应用，没有主窗口，Dock 里也不显示图标）。点它打开设置面板。

## 从源码构建

需要 macOS 13+ 与 Swift 工具链：

```bash
./script/build_and_run.sh          # 构建 + 打包 + 启动（开发用）
./script/package_dmg.sh 0.0.20     # 仅出可分发的 DMG 到 dist/
```

### 发布新版本

改完功能后，一条命令走完「打包 → 提交 → 推送 → 建 GitHub Release」：

```bash
./script/release.sh 0.0.20 "本次更新说明"
```

版本号用 `0.0.x` 线性递增，每改一次功能 +1（patch 保持两位数，如 0.0.20 → 0.0.21）。脚本会校验版本格式、是否在 main、版本号是否重复，并产出通用二进制（Apple Silicon + Intel）的 DMG。

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

## 依赖

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) —— 组合键录制。

## 已知事项

- 字符序列默认 `=n`，在正常文本中也可能误触（如 `x=n`）；可在设置里改成更少见的组合，如 `;now`。
- 单元测试当前使用 Swift Testing（`import Testing`），需完整 Xcode 工具链；纯 Command Line Tools 环境下 `swift test` 暂不可用。
