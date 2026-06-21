# Handoff: TimeStamp — 按快捷键插入当前时间（macOS 菜单栏小工具）

## Overview
TimeStamp 是一个 macOS 菜单栏小工具：用户按下一个全局快捷键（默认 ⌘⇧T），就把"当前时间"按用户设定的格式字符串输入到**当前聚焦的任意文本框**里。快捷键和时间格式都可在菜单栏下拉的设置面板中自定义。

本包提供：定稿的设置面板设计稿（`TimeStamp 成品.dc.html`）+ 一份带可编译代码片段的实现说明（`实现说明 给开发.dc.html`）。

## About the Design Files
本包内的 `.dc.html` 文件是**用 HTML 制作的设计参考**——展示预期外观与交互的原型，**不是可直接搬运的生产代码**。任务是把这些设计在目标环境里**重建为真正的 macOS 应用**。

这是一个原生 macOS 工具，不存在现成的前端代码库可套用。推荐技术栈：**Swift + SwiftUI（MenuBarExtra）**，全局快捷键用 [`KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts) 库。如只为自用，可走 Hammerspoon 脚本捷径（见实现说明）。HTML 原型仅用于确定 UI 外观与交互手感。

> ⚠️ 关键能力——注册系统级全局快捷键、模拟键盘把文字送进别的 App——**无法用 HTML/网页实现**，必须用原生代码或 Hammerspoon/Karabiner 类工具落地。HTML 原型只表达界面。

## Fidelity
**High-fidelity (hifi)。** 设置面板是像素级定稿，含最终配色、字体、间距与全部交互状态（快捷键录制态、开关态、hover）。开发应在 SwiftUI 中尽量还原其外观，并用原生系统控件实现等价交互。

## Screens / Views

### 1. 菜单栏下拉设置面板（唯一界面）
- **Name**：Settings Panel（点击菜单栏时钟图标弹出）
- **Purpose**：用户在此配置触发快捷键、时间格式，查看实时预览，并开关开机自启。
- **Surface**：macOS 菜单栏图标 → 点击弹出的 `.window` 样式下拉面板（非传统菜单）。
- **整体风格**：原生 macOS Big Sur+ 风格——半透明毛玻璃面板（`NSVisualEffectView` / SwiftUI material），圆角，分隔线，系统蓝 `#007AFF` 强调色。

**Layout（自上而下，单列）**：
1. **预览区**（padding 18px 18px 12px）
   - 小标签"将插入"：11px / 600 / `#86868B` / letter-spacing .02em
   - 大字预览：29px / 600 / `#1D1D1F` / tabular-nums / letter-spacing -.01em，内容为按当前格式格式化的当前时间（如 `2026-06-21 12:13`）
2. 分隔线 0.5px `rgba(0,0,0,.1)`
3. **触发快捷键行**（高 padding 13px 18px，space-between）
   - 左："触发快捷键" 14px `#1D1D1F`
   - 右：快捷键胶囊按钮（见组件）
4. 分隔线 0.5px `rgba(0,0,0,.07)`，左右内缩 18px
5. **时间格式区**（padding 13px 18px）
   - 标题"时间格式" 14px `#1D1D1F`，下边距 8px
   - 单行输入框（见组件）
   - 占位符 chips 行（flex-wrap，gap 6px，上边距 9px）
   - 预览行："预览 · `2026-06-21 12:13`" 12px `#86868B`（时间部分 `#1D1D1F`）
6. 分隔线
7. **登录时启动行**（space-between）
   - 左："登录时启动" 14px `#1D1D1F`
   - 右：iOS 风格开关（见组件）
8. 分隔线 0.5px `rgba(0,0,0,.1)`
9. **底部行**（padding 11px 18px，space-between）："偏好设置…" 与 "退出 ⌘Q"，均 13px `#86868B`

> 面板宽约 398px（外层 430px 容器，左右各 16px margin）。面板圆角 14px，阴影 `0 14px 44px rgba(0,0,0,.28), 0 0 0 .5px rgba(0,0,0,.12)`。

**Components**

- **快捷键胶囊（录制按钮）**
  - 默认态：背景 `rgba(120,120,128,.16)`，文字 `#1D1D1F`，13px / 600 / letter-spacing .04em，padding 5px 12px，圆角 8px，min-width 58px，居中。显示如 `⌘⇧T`（修饰键符号 ⌘⇧⌥⌃ 拼接）。
  - 录制态（点击后）：背景 `#007AFF`，文字白，外发光 `0 0 0 3px rgba(0,122,255,.25)`，显示"按键…"。此时捕获下一组按键并写回。
  - 交互：点击 → 进入录制态 → 监听键盘 → 按下非纯修饰键的组合后，记录修饰键符号 + 主键（大写），退出录制态。

- **格式输入框**
  - 等宽字体（SF Mono），13px，`#1D1D1F`
  - 背景 `rgba(255,255,255,.7)`，边框 0.5px `rgba(0,0,0,.14)`，圆角 8px，padding 9px 11px
  - 内容为 DateFormatter 格式串，如 `yyyy-MM-dd HH:mm`

- **占位符 chips**（共 8 个：`yyyy MM dd HH mm ss EEE a`）
  - SF Mono 11px，文字 `#007AFF`，背景 `rgba(0,122,255,.1)`，圆角 6px，padding 3px 8px
  - hover：背景 `rgba(0,122,255,.2)`
  - 点击：把该占位符**追加**到格式串末尾

- **iOS 风格开关（登录时启动）**
  - 轨道 40×24，圆角 13px；开=`#34C759`，关=`rgba(120,120,128,.3)`
  - 滑块 20×20 白色圆，阴影 `0 1px 3px rgba(0,0,0,.25)`，开时左偏移 18px，关时 2px，过渡 .15s

- **菜单栏图标区**（设计稿中的桌面演示部分，真实 App 中即菜单栏那一个时钟图标）
  - 图标 + 当前时间 `h:mm AM/PM`，12px / 600 / tabular-nums，白字

## Interactions & Behavior
- **录制快捷键**：点胶囊 → 监听 keydown → 忽略纯修饰键（Shift/Meta/Alt/Control/CapsLock）→ 组合出 [修饰键…, 主键] → 写回并退出录制。原生用 `KeyboardShortcuts.Recorder` 直接得到等价控件。
- **格式实时预览**：格式串任何变化 → 立即重算大字预览与底部预览（原生：`DateFormatter`）。
- **点 chip 追加占位符**：把字符串追加到格式串尾部。
- **开关**：切换开机自启（原生：`SMAppService.mainApp.register()/unregister()`）。
- **菜单栏时钟**：每秒刷新（原型用 1s setInterval）。
- **核心触发（原型无法演示）**：按下全局快捷键 → 用当前格式格式化 now → 把字符串送入当前文本框（推荐：写 NSPasteboard 后模拟 ⌘V，完成后还原剪贴板）。**需要"辅助功能"权限。**

## State Management
- `dateFormat: String`（持久化，默认 `"yyyy-MM-dd HH:mm"`）— 用 `@AppStorage` / UserDefaults
- `hotkey`（持久化）— 由 KeyboardShortcuts 库管理，默认 ⌘⇧T
- `launchAtLogin: Bool`（持久化）
- `recording: Bool`（瞬时 UI 态，仅录制控件内部）
- `now: Date`（每秒刷新，仅驱动预览/菜单栏时钟显示）

## Design Tokens
**Colors**
- 文字主色 `#1D1D1F`
- 次要文字 `#86868B`
- 强调蓝 `#007AFF`
- 开关绿 `#34C759`
- 控件灰底 `rgba(120,120,128,.16)`
- chip 蓝底 `rgba(0,122,255,.1)` / hover `rgba(0,122,255,.2)`
- 分隔线 `rgba(0,0,0,.1)`（主）/ `rgba(0,0,0,.07)`（内缩）
- 面板材质 `rgba(245,245,247,.82)` + blur(40px) saturate(180%)

**Typography**
- UI 文字：系统字体（-apple-system / SF Pro）。行项 14px，标签 11–13px。
- 大预览：29px / 600 / -.01em / tabular-nums
- 等宽（格式串、chips）：SF Mono 11–13px

**Radius**：面板 14px；输入框/胶囊 8px；chip 6px；开关轨道 13px
**Shadow**：面板 `0 14px 44px rgba(0,0,0,.28), 0 0 0 .5px rgba(0,0,0,.12)`；开关滑块 `0 1px 3px rgba(0,0,0,.25)`
**Spacing**：行内边距多为 13px 18px；区块间用 0.5px 分隔线

**格式占位符（DateFormatter 风格，面板展示用）**
`yyyy`年 `yy`两位年 `MM`/`M`月 `dd`/`d`日 `HH`/`H`24时 `hh`/`h`12时 `mm`分 `ss`秒 `EEE`周缩写 `EEEE`周全称 `a` AM/PM。
> 注意：Hammerspoon 走 strftime（`%Y %m %d %H %M %S`），与上面不同；面板里展示的是 DateFormatter 风格，原生 Swift 直接对应。

## Assets
无外部图片/图标资源。菜单栏与控件图标用 SF Symbols（如 `clock`）。原型里的 SF Symbol 字形（􀐬 等）仅为占位示意，原生用真实 SF Symbols 替换。

## Files
- `TimeStamp 成品.dc.html` — 定稿设置面板（可交互原型：录制快捷键、改格式实时预览、开关）
- `实现说明 给开发.dc.html` — 实现说明，含 Hammerspoon 完整脚本 + Swift 可编译片段（快捷键监听 / 剪贴板输入 / MenuBarExtra）+ 权限提示 + 原型↔代码对应表
- `support.js` — `.dc.html` 预览所需运行时（仅用于在浏览器里打开原型查看；与最终 App 无关）

> 用浏览器打开 `.dc.html` 即可查看并操作原型。最终交付物是一个原生 macOS App，**不要**直接打包这些 HTML。
