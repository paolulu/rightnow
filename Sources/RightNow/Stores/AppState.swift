import Foundation
@preconcurrency import KeyboardShortcuts
import RightNowCore

@MainActor
final class AppState: ObservableObject {
    private enum Keys {
        static let dateFormat = "dateFormat"
        static let sequenceTrigger = "sequenceTrigger"
    }

    static let defaultSequenceTrigger = "=n"

    private let defaults: UserDefaults
    private let sequenceService = SequenceTriggerService()

    @Published var dateFormat: String {
        didSet {
            defaults.set(dateFormat, forKey: Keys.dateFormat)
        }
    }

    /// 触发序列，例如 `=n`。
    @Published var sequenceTrigger: String {
        didSet {
            defaults.set(sequenceTrigger, forKey: Keys.sequenceTrigger)
            applySequenceTrigger()
        }
    }

    @Published private(set) var launchAtLoginEnabled: Bool
    @Published var launchAtLoginError: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.dateFormat = defaults.string(forKey: Keys.dateFormat) ?? TimestampFormatter.defaultFormat
        self.sequenceTrigger = defaults.string(forKey: Keys.sequenceTrigger) ?? Self.defaultSequenceTrigger
        self.launchAtLoginEnabled = LaunchAtLoginService.isEnabled

        KeyboardShortcuts.onKeyUp(for: .insertTimestamp) { [weak self] in
            self?.insertCurrentTimestamp()
        }

        sequenceService.onTrigger = { [weak self] backspaceCount in
            self?.insertCurrentTimestamp(deletingBackward: backspaceCount)
        }
        applySequenceTrigger()
    }

    private func applySequenceTrigger() {
        if !sequenceTrigger.isEmpty {
            sequenceService.start(trigger: sequenceTrigger)
        } else {
            sequenceService.stop()
        }
    }

    func preview(for date: Date) -> String {
        TimestampFormatter.string(from: date, format: dateFormat)
    }

    func appendToken(_ token: String) {
        dateFormat += token
    }

    func resetDateFormat() {
        dateFormat = TimestampFormatter.defaultFormat
    }

    func insertCurrentTimestamp(deletingBackward backspaceCount: Int = 0) {
        if !AccessibilityPermission.isTrusted {
            AccessibilityPermission.requestIfNeeded()
        }

        let text = TimestampFormatter.string(format: dateFormat)
        TextInsertionService.insert(text, deletingBackward: backspaceCount)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginService.setEnabled(enabled)
            launchAtLoginEnabled = LaunchAtLoginService.isEnabled
            launchAtLoginError = nil
        } catch {
            launchAtLoginEnabled = LaunchAtLoginService.isEnabled
            launchAtLoginError = error.localizedDescription
        }
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginEnabled = LaunchAtLoginService.isEnabled
    }
}
