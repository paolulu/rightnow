@preconcurrency import KeyboardShortcuts
import RightNowCore
import SwiftUI

private enum SettingsPanelMetrics {
    static let panelWidth: CGFloat = 344
    static let panelHeight: CGFloat = 476
    static let controlInputWidth: CGFloat = 156
    static let sequenceInputWidth: CGFloat = 112
    static let shortcutRecorderWidth: CGFloat = 132
    static let shortcutClearButtonWidth: CGFloat = 24
    static let inputHeight: CGFloat = 28
    static let inputCornerRadius: CGFloat = 6
    static let formatLabelWidth: CGFloat = 34
    static let previewValueHeight: CGFloat = 30
    static let footerHeight: CGFloat = 40
}

private enum FormatTokenKind {
    case field
    case separator
}

private struct FormatTokenGroup: Identifiable {
    let id: String
    let title: String
    let tokens: [String]
    let kind: FormatTokenKind
}

struct SettingsPanel: View {
    @ObservedObject var state: AppState
    @State private var showingReleaseNotes = false
    @State private var dateFormatSelection = NSRange(location: 0, length: 0)
    @State private var hasDateFormatSelection = false

    var body: some View {
        Group {
            if showingReleaseNotes {
                ReleaseNotesView(
                    currentVersion: appVersion,
                    onBack: { showingReleaseNotes = false },
                    onOpenInBrowser: { openReleaseNotes() }
                )
            } else {
                settingsContent
            }
        }
        .frame(width: SettingsPanelMetrics.panelWidth, height: SettingsPanelMetrics.panelHeight)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 22, x: 0, y: 14)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.black.opacity(0.12), lineWidth: 0.5)
        }
    }

    private var settingsContent: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 0) {
                previewSection(date: context.date)
                insetSeparator()
                formatSection
                separator()
                shortcutSection
                insetSeparator()
                sequenceSection
                insetSeparator()
                launchSection
                Spacer(minLength: 0)
                separator()
                footer
            }
            .frame(height: SettingsPanelMetrics.panelHeight, alignment: .top)
            .onAppear {
                state.refreshLaunchAtLoginStatus()
            }
        }
    }

    private func previewSection(date: Date) -> some View {
        let preview = state.preview(for: date)

        return VStack(alignment: .leading, spacing: 3) {
            Text("时间预览")
                .font(.system(size: 14))
                .foregroundStyle(.primary)
            Text(preview)
                .font(.system(size: previewFontSize(for: preview), weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .truncationMode(.tail)
                .allowsTightening(true)
                .foregroundStyle(.primary)
                .frame(height: SettingsPanelMetrics.previewValueHeight, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 14)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    private func previewFontSize(for text: String) -> CGFloat {
        switch (text as NSString).length {
        case 0...17:
            24
        case 18...23:
            20
        case 24...29:
            18
        default:
            16
        }
    }

    private var shortcutSection: some View {
        HStack {
            Text("触发快捷键")
                .font(.system(size: 14))
            Spacer()
            ShortcutRecorderControl(for: .insertTimestamp)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }

    private var sequenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("字符序列触发")
                        .font(.system(size: 14))
                    Text("留空则关闭，依次按下即可触发。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.9)
                }
                Spacer()
                TextField("=n", text: Binding(
                    get: { state.sequenceTrigger },
                    set: { state.sequenceTrigger = $0 }
                ))
                .font(.system(size: 13, design: .monospaced))
                .textFieldStyle(.plain)
                .settingsInputChrome(width: SettingsPanelMetrics.sequenceInputWidth)
            }

        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("时间格式")
                    .font(.system(size: 14))
                Spacer()
                Button {
                    resetDateFormat()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .foregroundStyle(state.dateFormat == TimestampFormatter.defaultFormat ? .secondary : Color.accentColor)
                .disabled(state.dateFormat == TimestampFormatter.defaultFormat)
                .help("恢复默认")
            }

            DateFormatTextField(text: Binding(
                get: { state.dateFormat },
                set: { state.dateFormat = $0 }
            ), selection: $dateFormatSelection, hasSelection: $hasDateFormatSelection)
            .settingsInputChrome()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(formatTokenGroups) { group in
                    HStack(alignment: .center, spacing: 10) {
                        Text(group.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: SettingsPanelMetrics.formatLabelWidth, alignment: .leading)

                        HStack(spacing: 6) {
                            ForEach(group.tokens, id: \.self) { token in
                                Button {
                                    insertFormatToken(token)
                                } label: {
                                    Text(formatTokenTitle(token))
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(formatTokenForeground(for: group.kind))
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 10)
                                        .background(formatTokenBackground(for: group.kind))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.top, 3)

        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }

    private var launchSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("登录时启动")
                    .font(.system(size: 14))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { state.launchAtLoginEnabled },
                    set: { state.setLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.green)
            }

            if let error = state.launchAtLoginError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }

    private var footer: some View {
        HStack {
            Button {
                AccessibilityPermission.openSystemSettings()
            } label: {
                footerLabel("打开权限设置")
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showingReleaseNotes = true
            } label: {
                footerLabel("v\(appVersion)")
            }
            .buttonStyle(.plain)
            .help("查看版本更新内容")

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                footerLabel("退出 ⌘Q")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .frame(height: SettingsPanelMetrics.footerHeight, alignment: .center)
    }

    private func footerLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(height: SettingsPanelMetrics.footerHeight, alignment: .center)
            .contentShape(Rectangle())
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    private func openReleaseNotes() {
        guard let url = URL(string: "https://github.com/paolulu/rightnow/releases") else { return }
        NSWorkspace.shared.open(url)
    }

    private func separator() -> some View {
        Rectangle()
            .fill(.black.opacity(0.1))
            .frame(height: 0.5)
    }

    private func insetSeparator() -> some View {
        Rectangle()
            .fill(.black.opacity(0.07))
            .frame(height: 0.5)
            .padding(.horizontal, 18)
    }

    private func formatTokenTitle(_ token: String) -> String {
        token == " " ? "空格" : token
    }

    private var formatTokenGroups: [FormatTokenGroup] {
        [
            FormatTokenGroup(id: "date", title: "日期", tokens: ["yyyy", "MM", "dd", "EEE"], kind: .field),
            FormatTokenGroup(id: "time", title: "时间", tokens: ["HH", "mm", "ss", "a"], kind: .field),
            FormatTokenGroup(id: "separator", title: "分隔", tokens: ["-", " ", ":"], kind: .separator)
        ]
    }

    private func formatTokenForeground(for kind: FormatTokenKind) -> Color {
        switch kind {
        case .field:
            Color.accentColor
        case .separator:
            .secondary
        }
    }

    private func formatTokenBackground(for kind: FormatTokenKind) -> Color {
        switch kind {
        case .field:
            Color.accentColor.opacity(0.14)
        case .separator:
            Color.secondary.opacity(0.12)
        }
    }

    private func insertFormatToken(_ token: String) {
        let text = state.dateFormat as NSString
        let range = hasDateFormatSelection
            ? clampedDateFormatSelection(for: text)
            : NSRange(location: text.length, length: 0)
        state.dateFormat = text.replacingCharacters(in: range, with: token)
        let nextSelection = NSRange(location: range.location + (token as NSString).length, length: 0)
        DispatchQueue.main.async {
            dateFormatSelection = nextSelection
            hasDateFormatSelection = true
        }
    }

    private func resetDateFormat() {
        state.resetDateFormat()
        let length = (TimestampFormatter.defaultFormat as NSString).length
        dateFormatSelection = NSRange(location: length, length: 0)
        hasDateFormatSelection = true
    }

    private func clampedDateFormatSelection(for text: NSString) -> NSRange {
        let location = min(max(dateFormatSelection.location, 0), text.length)
        let maxLength = text.length - location
        let length = min(max(dateFormatSelection.length, 0), maxLength)
        return NSRange(location: location, length: length)
    }
}

private struct DateFormatTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange
    @Binding var hasSelection: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, selection: $selection, hasSelection: $hasSelection)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(string: text)
        textField.delegate = context.coordinator
        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textField.lineBreakMode = .byTruncatingTail
        textField.usesSingleLineMode = true
        textField.alignment = .left
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.updateBindings(text: $text, selection: $selection, hasSelection: $hasSelection)

        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        guard let editor = nsView.currentEditor() else {
            return
        }

        if editor.string != text {
            editor.string = text
        }

        let range = clamped(selection, in: editor.string)
        if !NSEqualRanges(editor.selectedRange, range) {
            editor.selectedRange = range
        }
    }

    private func clamped(_ range: NSRange, in text: String) -> NSRange {
        let length = (text as NSString).length
        let location = min(max(range.location, 0), length)
        return NSRange(location: location, length: min(max(range.length, 0), length - location))
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        private var text: Binding<String>
        private var selection: Binding<NSRange>
        private var hasSelection: Binding<Bool>
        private weak var observedEditor: NSText?

        init(text: Binding<String>, selection: Binding<NSRange>, hasSelection: Binding<Bool>) {
            self.text = text
            self.selection = selection
            self.hasSelection = hasSelection
        }

        deinit {
            removeSelectionObserver()
        }

        func updateBindings(
            text: Binding<String>,
            selection: Binding<NSRange>,
            hasSelection: Binding<Bool>
        ) {
            self.text = text
            self.selection = selection
            self.hasSelection = hasSelection
        }

        func controlTextDidBeginEditing(_ notification: Notification) {
            guard let editor = notification.userInfo?["NSFieldEditor"] as? NSText else {
                return
            }
            observeSelection(in: editor)
            updateSelection(editor.selectedRange)
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }
            text.wrappedValue = textField.stringValue

            if let editor = textField.currentEditor() {
                updateSelection(editor.selectedRange)
            }
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            if let textField = notification.object as? NSTextField {
                text.wrappedValue = textField.stringValue
            }
            removeSelectionObserver()
        }

        private func observeSelection(in editor: NSText) {
            removeSelectionObserver()
            observedEditor = editor
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(editorSelectionDidChange(_:)),
                name: NSTextView.didChangeSelectionNotification,
                object: editor
            )
        }

        @MainActor
        @objc private func editorSelectionDidChange(_ notification: Notification) {
            guard let editor = notification.object as? NSText else {
                return
            }
            updateSelection(editor.selectedRange)
        }

        private func updateSelection(_ range: NSRange) {
            selection.wrappedValue = range
            hasSelection.wrappedValue = true
        }

        private func removeSelectionObserver() {
            if let observedEditor {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSTextView.didChangeSelectionNotification,
                    object: observedEditor
                )
                self.observedEditor = nil
            }
        }
    }
}

private struct ShortcutRecorderControl: View {
    let name: KeyboardShortcuts.Name

    init(for name: KeyboardShortcuts.Name) {
        self.name = name
    }

    var body: some View {
        HStack(spacing: 0) {
            ShortcutRecorderField(for: name)
                .frame(
                    width: SettingsPanelMetrics.shortcutRecorderWidth,
                    height: SettingsPanelMetrics.inputHeight
                )

            Button {
                KeyboardShortcuts.setShortcut(nil, for: name)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(
                        width: SettingsPanelMetrics.shortcutClearButtonWidth,
                        height: SettingsPanelMetrics.inputHeight
                    )
            }
            .buttonStyle(.plain)
            .help("清除快捷键")
        }
        .settingsInputChrome(
            width: SettingsPanelMetrics.controlInputWidth,
            horizontalPadding: 0
        )
    }
}

private struct ShortcutRecorderField: NSViewRepresentable {
    let name: KeyboardShortcuts.Name

    init(for name: KeyboardShortcuts.Name) {
        self.name = name
    }

    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        let recorder = KeyboardShortcuts.RecorderCocoa(for: name)
        configure(recorder)
        return recorder
    }

    func updateNSView(_ nsView: KeyboardShortcuts.RecorderCocoa, context: Context) {
        nsView.shortcutName = name
        configure(nsView)
    }

    private func configure(_ recorder: KeyboardShortcuts.RecorderCocoa) {
        recorder.isBezeled = false
        recorder.drawsBackground = false
        recorder.focusRingType = .none
        recorder.controlSize = .small
        recorder.font = .systemFont(ofSize: 13)
        recorder.alignment = .center
        (recorder.cell as? NSSearchFieldCell)?.cancelButtonCell = nil
    }
}

private extension View {
    @ViewBuilder
    func settingsInputChrome(
        width: CGFloat? = nil,
        horizontalPadding: CGFloat = 10
    ) -> some View {
        if let width {
            settingsInputBase(horizontalPadding: horizontalPadding)
                .frame(
                    width: width,
                    height: SettingsPanelMetrics.inputHeight,
                    alignment: .leading
                )
                .settingsInputBackground()
        } else {
            settingsInputBase(horizontalPadding: horizontalPadding)
                .frame(
                    maxWidth: .infinity,
                    minHeight: SettingsPanelMetrics.inputHeight,
                    maxHeight: SettingsPanelMetrics.inputHeight,
                    alignment: .leading
                )
                .settingsInputBackground()
        }
    }

    private func settingsInputBase(horizontalPadding: CGFloat) -> some View {
        padding(.horizontal, horizontalPadding)
    }

    private func settingsInputBackground() -> some View {
        background(.white.opacity(0.7))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: SettingsPanelMetrics.inputCornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: SettingsPanelMetrics.inputCornerRadius,
                    style: .continuous
                )
                .stroke(.black.opacity(0.14), lineWidth: 0.5)
            }
    }
}
