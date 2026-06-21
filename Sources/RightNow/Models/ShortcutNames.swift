@preconcurrency import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    @MainActor
    static let insertTimestamp = Self(
        "insertTimestamp",
        default: .init(.t, modifiers: [.command, .shift])
    )
}
