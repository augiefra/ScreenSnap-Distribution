import SwiftUI
import AppKit

@main
struct ScreenSnapAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var screenshotService: ScreenshotService?
    var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "ScreenSnap")
            button.action = #selector(togglePopover)
        }

        // Initialize services
        screenshotService = ScreenshotService()
        hotKeyManager = HotKeyManager()

        // Setup menu
        setupMenu()

        // Register hotkey
        hotKeyManager?.registerHotKey()
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if let popover = popover, popover.isShown {
                popover.performClose(nil)
            } else {
                showPopover(button)
            }
        }
    }

    func showPopover(_ sender: NSButton) {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: SettingsView())
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        self.popover = popover
    }

    func setupMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Prendre une capture", action: #selector(takeScreenshot), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Préférences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quitter", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func takeScreenshot() {
        screenshotService?.captureScreenshot()
    }

    @objc func openPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
