import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let state = AppState()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        AccessibilityPermission.requestIfNeeded()
    }

    private func configureStatusItem() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 430, height: 540)
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
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
