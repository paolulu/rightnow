import AppKit

@MainActor
enum TextInsertionService {
    /// 把 `text` 粘贴到当前焦点处。
    /// - Parameter backspaceCount: 粘贴前先向前删除的字符数（用于清掉序列触发时输入的触发字符）。
    static func insert(_ text: String, deletingBackward backspaceCount: Int = 0) {
        let pasteboard = NSPasteboard.general
        let previousItems = copyItems(from: pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let insertedChangeCount = pasteboard.changeCount

        let source = CGEventSource(stateID: .combinedSessionState)
        let keyCodeDelete: CGKeyCode = 0x33
        for _ in 0..<max(0, backspaceCount) {
            postKey(keyCodeDelete, flags: [], source: source)
        }
        postKey(0x09, flags: .maskCommand, source: source) // V

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard pasteboard.changeCount == insertedChangeCount else {
                return
            }

            pasteboard.clearContents()
            if !previousItems.isEmpty {
                pasteboard.writeObjects(previousItems)
            }
        }
    }

    private static func copyItems(from pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        pasteboard.pasteboardItems?.map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        } ?? []
    }

    private static func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags, source: CGEventSource?) {
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)

        keyDown?.flags = flags
        keyUp?.flags = flags
        // 标记成我们自己的合成事件，避免 SequenceTriggerService 把它当成用户输入。
        keyDown?.setIntegerValueField(.eventSourceUserData, value: SequenceTriggerService.syntheticEventMarker)
        keyUp?.setIntegerValueField(.eventSourceUserData, value: SequenceTriggerService.syntheticEventMarker)
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
