import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let state = AppState()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()

#if DEBUG
    private var previewWindow: NSWindow?
#endif

    func applicationDidFinishLaunching(_ notification: Notification) {
#if DEBUG
        NSApp.setActivationPolicy(.regular)
#else
        NSApp.setActivationPolicy(.accessory)
#endif
        configureStatusItem()
        AccessibilityPermission.requestIfNeeded()

#if DEBUG
        showDevelopmentPreviewWindow()
#endif
    }

    private func configureStatusItem() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 344, height: 476)
        popover.contentViewController = NSHostingController(rootView: SettingsPanel(state: state))

        if let button = statusItem.button {
            button.image = statusBarImage()
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    /// 菜单栏图标：打包进 app 的键帽图（彩色，保留原色，非模板渲染）。
    private func statusBarImage() -> NSImage? {
        guard
            let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else {
            return NSImage(systemSymbolName: "clock", accessibilityDescription: "RightNow")
        }
        let height: CGFloat = 18
        let width = height * (image.size.width / max(image.size.height, 1))
        image.size = NSSize(width: width, height: height)
        image.isTemplate = false
        return image
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            if let window = popover.contentViewController?.view.window {
                window.makeKey()
                DispatchQueue.main.async { [weak window] in
                    window?.makeFirstResponder(nil)
                }
            }
        }
    }

#if DEBUG
    private func showDevelopmentPreviewWindow() {
        let contentSize = NSSize(width: 344, height: 476)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "RightNow Preview"
        window.contentView = NSHostingView(rootView: SettingsPanel(state: state))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        previewWindow = window

        NSApp.activate(ignoringOtherApps: true)
    }
#endif
}
