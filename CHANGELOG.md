# RightNow Changelog / Handoff

## 2026-06-21 当前阶段

项目已经从“普通窗口可见版”调整为“菜单栏状态栏版”。

当前运行方式：

```bash
./script/build_and_run.sh
```

当前效果：

- `RightNow` 作为后台菜单栏应用运行，Dock 不显示普通 App 图标。
- macOS 顶部菜单栏右侧会出现 `Now HH:mm`。
- 点击 `Now HH:mm` 会弹出设置面板。
- 设置面板复用 `SettingsPanel`，里面包含快捷键录制、时间格式、预览、登录时启动、退出按钮。

已验证：

- `swift build` 通过。
- `./script/build_and_run.sh` 能构建、打包、启动。
- `System Events` 能看到 `RightNow` 作为后台菜单栏应用运行。
- `Computer Use` 已看到菜单栏 popover 中的设置面板元素。

## 2026-06-21 新增「字符序列触发」

除了原有的组合键（KeyboardShortcuts，⌘⇧T 之类），新增一种**依次按字符**的触发方式：
先按 `=` 再按 `n`（默认序列 `=n`，可在设置面板修改）即可插入时间戳。

实现要点：

- 新增 `Sources/RightNow/Services/SequenceTriggerService.swift`
  - 用 `NSEvent.addGlobalMonitorForEvents(.keyDown)` 被动监听全局键盘。
  - 维护最近输入字符缓冲，命中触发序列后回调；超过 1.5s 间隔、遇到空格/回车/方向键或 ⌘/⌃/⌥ 都会重置序列。
  - 复用已有的辅助功能权限，无需新授权。被动监听不会“吞掉”按键，因此触发后由 `TextInsertionService` 发退格删掉已输入的触发字符。
- `TextInsertionService.insert(_:deletingBackward:)`
  - 粘贴前先发送 N 个退格（N = 触发序列长度）。
  - 退格与 ⌘V 都用 `eventSourceUserData` 打标记，避免被监听器当成用户输入而自我触发。
- `AppState`
  - 新增 `sequenceTriggerEnabled`（默认开）与 `sequenceTrigger`（默认 `=n`），持久化到 `UserDefaults`。
  - 拥有并接线 `SequenceTriggerService`，命中后调用 `insertCurrentTimestamp(deletingBackward:)`。
- `SettingsPanel`
  - 在「触发快捷键」下方新增「字符序列触发」开关 + 序列输入框 + 说明。

注意事项：

- 序列字符会先真实输入再被退格删除，理论上有极短闪烁（通常 <50ms 不可见）。
- 默认 `=n` 在正常文本里也可能误触（例如打公式 `x=n`）。可在设置里改成更少见的组合，如 `;now`。
- 编辑设置面板时 RightNow 是前台应用，全局监听只对“其他应用”生效，因此在格式/序列输入框里打字不会自我触发。

## 主要调整记录

1. 初始项目检查
   - 项目是 SwiftPM macOS App。
   - `Package.swift` 产物包括 `RightNowCore` library 和 `RightNow` executable。
   - 核心能力已经存在：时间格式化、全局快捷键、剪贴板 + Cmd-V 插入文本、辅助功能权限、自启动开关。

2. 构建与测试
   - `swift build` 成功。
   - `swift test` 失败，原因是测试使用 `import Testing`，当前 Command Line Tools 环境找不到 `Testing` 模块。
   - `xcodebuild -version` 失败，当前机器只选中 Command Line Tools，不是完整 Xcode。

3. 运行脚本修正
   - `script/build_and_run.sh` 原本没有执行权限，已加执行权限。
   - 脚本负责：停止旧进程、`swift build`、生成 `dist/RightNow.app`、复制资源 bundle、写 `Info.plist`、启动 App。
   - 停止旧进程时补了基于 app bundle 路径的 `pkill -f`，避免旧实例残留。

4. 普通窗口阶段
   - 因为用户反馈 `./script/build_and_run.sh` “没反应”，临时把 App 改成普通窗口模式。
   - 普通窗口模式确认可显示 `SettingsPanel`。
   - 遇到过窗口出现在不可见位置的问题，曾用 AppleScript 把窗口移到 `{700, 220}`。
   - 这个阶段只是为了确认 UI 能显示，后来已转回菜单栏应用。

5. `MenuBarExtra` 尝试
   - 先恢复 SwiftUI `MenuBarExtra`。
   - 发现 `Label` 在菜单栏里只显示图标，文字 `Now HH:mm` 不明显。
   - 改成纯 `Text("Now HH:mm")` 后仍受菜单栏空间/整理工具影响，不够可靠。

6. 当前最终实现：AppKit `NSStatusItem`
   - `RightNowApp` 现在只保留一个空的 `Settings` scene，用于维持 SwiftUI App 生命周期。
   - `AppDelegate` 创建 `NSStatusBar.system.statusItem`。
   - 状态栏按钮标题每秒刷新为 `Now HH:mm`。
   - 点击状态栏按钮时，通过 `NSPopover` 展示 `SettingsPanel(state:)`。
   - `Info.plist` 中 `LSUIElement=true`，所以它是后台菜单栏应用。

## 当前关键文件

- `Sources/RightNow/App/RightNowApp.swift`
  - SwiftUI App 入口。
  - 当前只注册 `AppDelegate` 和空 `Settings` scene。

- `Sources/RightNow/App/AppDelegate.swift`
  - 当前菜单栏实现核心。
  - 创建 `NSStatusItem`。
  - 创建 `NSPopover`，承载 `SettingsPanel`。
  - 每秒刷新菜单栏标题。

- `Sources/RightNow/Views/SettingsPanel.swift`
  - 设置面板 UI。
  - 当前同时服务菜单栏 popover。

- `Sources/RightNow/Stores/AppState.swift`
  - 应用状态、快捷键注册、格式保存、插入当前时间、自启动开关。

- `script/build_and_run.sh`
  - 当前推荐运行入口。
  - 会打包为 `dist/RightNow.app` 并启动。

- `.codex/environments/environment.toml`
  - Codex Run action 指向 `./script/build_and_run.sh`。

## 遇到的问题

1. Codex 里没有看到 Run 按钮
   - 项目中 `.codex/environments/environment.toml` 已存在。
   - 但 Codex UI 不一定会实时刷新 action。
   - Computer Use 不能操作 Codex 自己，无法直接替用户确认 Codex UI。

2. 菜单栏 App 启动后“没反应”
   - 菜单栏应用本来没有普通窗口。
   - 原来只看进程是不够的，需要确认顶部状态栏项是否可见。

3. `WindowGroup` + `MenuBarExtra` 组合问题
   - 普通窗口和菜单栏同时复用同一个 `SettingsPanel` 时，曾出现 SwiftUI fatal：
     `SwiftUI/AppWindowsController.swift:117: Fatal error`
   - 加不同 Scene id 后不再 fatal，但窗口仍未稳定自动显示。
   - 最终没有采用这个路线。

4. SwiftUI `MenuBarExtra` 显示不可靠
   - 在当前菜单栏图标很多的环境下，SwiftUI `MenuBarExtra` 的文字不够明确。
   - 最终改用 AppKit `NSStatusItem`，状态项明确显示 `Now HH:mm`。

5. 测试工具链问题
   - `swift test` 当前失败在 `import Testing`。
   - 如果继续需要自动化测试，建议把测试改为 `XCTest`，或者切到带 Swift Testing 的完整 Xcode 工具链。

## 下一步建议

1. 验证真实快捷键插入
   - 打开任意输入框。
   - 点击菜单栏 `Now HH:mm`，设置快捷键。
   - 按快捷键，确认当前时间能插入文本框。
   - 如果没有插入，优先检查 macOS 辅助功能权限。

2. 调整菜单栏显示文案
   - 当前是 `Now HH:mm`。
   - 可以改成更短的 `Now`、`RN`，或者中文 `现在 HH:mm`。
   - 如果菜单栏空间紧张，建议保留短文本。

3. 修复测试
   - 把 `Tests/RightNowCoreTests/TimestampFormatterTests.swift` 从 Swift Testing 改成 XCTest。
   - 目标是让 `swift test` 在当前 Command Line Tools 环境下通过。

4. 检查登录时启动
   - 现在代码使用 `SMAppService.mainApp`。
   - 需要确认当前 SwiftPM 手工打包出来的 `.app` 是否满足 ServiceManagement 的实际要求。

5. 交付前整理
   - 增加 `README.md` 使用说明。
   - 考虑 release 打包、签名、图标、版本号。
   - 当前仓库还没有初始 commit，所有文件仍是未跟踪状态。
