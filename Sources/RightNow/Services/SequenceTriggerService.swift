import AppKit

/// 监听全局键盘，识别“依次按下的字符序列”（例如先按 `=` 再按 `n`）。
///
/// 与 `KeyboardShortcuts` 的组合键不同，这里是文本扩展式触发：
/// 用户按出的字符会真实输入到目标应用，命中序列后由调用方发送退格删除，再插入内容。
@MainActor
final class SequenceTriggerService {
    /// 标记我们自己合成的事件（退格、⌘V），避免被监听器再次当成用户输入。
    static let syntheticEventMarker: Int64 = 0x52_4E_4F_57 // "RNOW"

    /// 命中后回调，参数是需要向前删除的字符数（= 触发序列长度）。
    var onTrigger: ((Int) -> Void)?

    private var monitor: Any?
    private var buffer = ""
    private var lastKeyDate = Date.distantPast
    private(set) var trigger = ""

    /// 两次按键之间超过该间隔则重置序列，避免“几分钟前按过 = 现在按 n”误触发。
    private let resetInterval: TimeInterval = 1.5

    var isRunning: Bool { monitor != nil }

    func start(trigger: String) {
        self.trigger = trigger
        stop()
        guard !trigger.isEmpty else { return }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        buffer.removeAll()
    }

    func update(trigger newTrigger: String) {
        if isRunning {
            start(trigger: newTrigger)
        } else {
            trigger = newTrigger
        }
    }

    private func handle(_ event: NSEvent) {
        // 跳过我们自己合成的退格 / ⌘V 事件。
        if event.cgEvent?.getIntegerValueField(.eventSourceUserData) == Self.syntheticEventMarker {
            return
        }

        // 任意 ⌘/⌃/⌥ 都打断序列（Shift 允许，用于输入符号）。
        if !event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
            buffer.removeAll()
            return
        }

        let now = Date()
        if now.timeIntervalSince(lastKeyDate) > resetInterval {
            buffer.removeAll()
        }
        lastKeyDate = now

        // 只接受单个可见字符；空格、回车、方向键等都会打断序列。
        guard
            let characters = event.charactersIgnoringModifiers,
            characters.count == 1,
            let scalar = characters.unicodeScalars.first,
            !CharacterSet.whitespacesAndNewlines.contains(scalar),
            !CharacterSet.controlCharacters.contains(scalar)
        else {
            buffer.removeAll()
            return
        }

        buffer.append(characters)
        if buffer.count > trigger.count {
            buffer = String(buffer.suffix(trigger.count))
        }

        if buffer == trigger {
            buffer.removeAll()
            onTrigger?(trigger.count)
        }
    }
}
