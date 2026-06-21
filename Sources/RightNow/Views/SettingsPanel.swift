@preconcurrency import KeyboardShortcuts
import RightNowCore
import SwiftUI

struct SettingsPanel: View {
    @ObservedObject var state: AppState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 0) {
                previewSection(date: context.date)
                separator()
                shortcutSection
                insetSeparator()
                sequenceSection
                insetSeparator()
                formatSection(date: context.date)
                insetSeparator()
                launchSection
                separator()
                footer
            }
            .frame(width: 398)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.28), radius: 22, x: 0, y: 14)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.black.opacity(0.12), lineWidth: 0.5)
            }
            .padding(12)
            .onAppear {
                state.refreshLaunchAtLoginStatus()
            }
        }
    }

    private func previewSection(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("将插入")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(state.preview(for: date))
                .font(.system(size: 29, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    private var shortcutSection: some View {
        HStack {
            Text("触发快捷键")
                .font(.system(size: 14))
            Spacer()
            KeyboardShortcuts.Recorder(for: .insertTimestamp)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
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
                    Text("依次按下即可，无需修饰键")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { state.sequenceTriggerEnabled },
                    set: { state.sequenceTriggerEnabled = $0 }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.green)
            }

            if state.sequenceTriggerEnabled {
                TextField("=n", text: Binding(
                    get: { state.sequenceTrigger },
                    set: { state.sequenceTrigger = $0 }
                ))
                .font(.system(size: 13, design: .monospaced))
                .textFieldStyle(.plain)
                .padding(.vertical, 9)
                .padding(.horizontal, 11)
                .background(.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.black.opacity(0.14), lineWidth: 0.5)
                }

                Text("触发后会自动删除输入的这些字符。建议用不常见组合，如 =n、;now")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }

    private func formatSection(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间格式")
                .font(.system(size: 14))

            TextField("", text: Binding(
                get: { state.dateFormat },
                set: { state.dateFormat = $0 }
            ))
            .font(.system(size: 13, design: .monospaced))
            .textFieldStyle(.plain)
            .padding(.vertical, 9)
            .padding(.horizontal, 11)
            .background(.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black.opacity(0.14), lineWidth: 0.5)
            }

            FlowLayout(spacing: 6, rowSpacing: 6) {
                ForEach(TimestampFormatter.suggestedTokens, id: \.self) { token in
                    Button {
                        state.appendToken(token)
                    } label: {
                        Text(token)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.accentColor)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 1)

            HStack(spacing: 4) {
                Text("预览 ·")
                    .foregroundStyle(.secondary)
                Text(state.preview(for: date))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
            .font(.system(size: 12))
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
            Button("偏好设置…") {
                AccessibilityPermission.openSystemSettings()
            }
            .buttonStyle(.plain)

            Spacer()

            Button("退出 ⌘Q") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
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
}
