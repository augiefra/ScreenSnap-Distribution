//
//  PastScreenApp.swift
//  PastScreen
//
//  Created by Eric COLOGNI on 03/11/2025.
//

import SwiftUI
import AppKit
import UserNotifications
import Combine
#if !APPSTORE
import Sparkle
#endif
#if canImport(TipKit)
import TipKit
#endif

// Notification names
extension Notification.Name {
    static let screenshotCaptured = Notification.Name("screenshotCaptured")
    static let showInDockChanged = Notification.Name("showInDockChanged")
    static let hotKeyPressed = Notification.Name("hotKeyPressed")
}

@main
struct PastScreenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Application de menu bar uniquement - pas de fenêtre visible
        Settings {
            EmptyView()
        }
    }
}

enum CaptureTrigger: String {
    case menuBar
    case hotkey
    case appIntent
    case automation
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?  // Référence persistante au menu
    var screenshotService: ScreenshotService?
    var preferencesWindow: NSWindow?
    var preferencesWindowDelegate: PreferencesWindowDelegate?  // Strong reference
    private var hasPromptedAccessibility = false
    private var hasPromptedScreenRecording = false

    // Services
    var permissionManager = PermissionManager.shared

    #if !APPSTORE
    // Sparkle auto-updater
    private var updaterController: SPUStandardUpdaterController?
    #endif

    var settings = AppSettings.shared
    private let hotKeyManager = HotKeyManager.shared

    // Track last screenshot for "Reveal in Finder" menu item
    var lastScreenshotPath: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("🎯 [APP] ====== APPLICATION DID FINISH LAUNCHING ======")
        // Vérifier qu'une seule instance tourne
        if let bundleID = Bundle.main.bundleIdentifier {
            let runningInstances = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            if runningInstances.count > 1 {
                NSLog("⚠️ [APP] Une autre instance de PastScreen est déjà en cours d'exécution (\(runningInstances.count))")
                NSLog("💡 [APP] PastScreen est limité à une seule instance - arrêt de cette nouvelle instance")
                NSApp.terminate(nil)
                return
            }
        }

        // Setup notification center delegate
        UNUserNotificationCenter.current().delegate = self

#if canImport(TipKit)
        if #available(macOS 14.0, *) {
            try? Tips.configure()
        }
#endif
        ScreenshotIntentBridge.shared.appDelegate = self

        // IMPORTANT: Don't check permissions at startup to avoid system pop-ups
        // Permissions will be requested through the onboarding flow
        // permissionManager.checkAllPermissions()

        // Don't request notification permission automatically
        // permissionManager.requestPermission(.notifications) { granted in
        //     if granted {
        //         print("✅ [APP] Notifications authorized")
        //     } else {
        //         print("⚠️ [APP] Notifications not authorized - DynamicIslandManager will provide feedback")
        //     }
        // }

        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Utiliser l'icône personnalisée depuis Assets.xcassets
            if let icon = NSImage(named: "MenuBarIcon") {
                icon.isTemplate = true  // Adaptation automatique au thème clair/sombre
                button.image = icon
                print("✅ Custom MenuBarIcon loaded from Assets")
            } else {
                // Fallback vers SF Symbol
                button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "PastScreen")
                print("⚠️ Fallback: camera.viewfinder SF Symbol")
            }

            button.action = #selector(handleButtonClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "PastScreen - Raccourci: ⌥⌘S"
        }

        // Initialize services
        screenshotService = ScreenshotService()

        // Setup menu
        setupMenu()

        // NOTE: Permissions are now requested via Onboarding only
        // No auto-prompting at launch to avoid popup chaos

        #if DEBUG
        testNotification()
        #endif

        // Start monitoring for the global hotkey. The manager will handle settings changes internally.
        hotKeyManager.startMonitoring()

        // Observe when the hotkey is pressed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotKeyPressed),
            name: .hotKeyPressed,
            object: nil
        )

        // Check permission status (read-only, no popups)
        permissionManager.checkAllPermissions()

        // Observer les captures d'écran réussies pour mettre à jour lastScreenshotPath
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenshotCaptured),
            name: .screenshotCaptured,
            object: nil
        )

        // Observer les changements du mode Dock
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowInDockChanged),
            name: .showInDockChanged,
            object: nil
        )

        // Configurer le mode initial (Dock ou menu bar seulement)
        updateActivationPolicy()

        // Show onboarding if first launch
        NSLog("🚀 [APP] About to show onboarding...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard self != nil else { return }
            NSLog("🚀 [APP] Calling OnboardingManager.showIfNeeded()")
            OnboardingManager.shared.showIfNeeded()
        }

        #if !APPSTORE
        // Initialize Sparkle auto-updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        NSLog("✅ [SPARKLE] Auto-updater initialized")
        #else
        NSLog("ℹ️ [APP] Running App Store build - Sparkle disabled")
        #endif
    }

    @objc func handleScreenshotCaptured(_ notification: Notification) {
        if let path = notification.userInfo?["filePath"] as? String {
            lastScreenshotPath = path
            print("📝 [APP] Dernière capture mise à jour: \(path)")
        }
    }

    @objc func handleButtonClick() {
        // Tout clic (gauche ou droit) ouvre le menu - comportement standard des apps menu bar
        if let button = statusItem?.button {
            statusMenu = createMenu()  // Recréer pour mettre à jour "Voir la dernière capture"
            statusMenu?.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
        }
    }

    func setupMenu() {
        // Créer le menu une seule fois mais NE PAS l'assigner au statusItem
        // On l'affichera manuellement lors du clic droit
        statusMenu = createMenu()
    }

    func createMenu() -> NSMenu {
        let menu = NSMenu()

        let screenshotItem = NSMenuItem(title: NSLocalizedString("menu.capture_area", comment: ""), action: #selector(takeScreenshot), keyEquivalent: "")
        screenshotItem.target = self
        screenshotItem.keyEquivalent = "s"
        screenshotItem.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(screenshotItem)

        let fullScreenItem = NSMenuItem(title: NSLocalizedString("menu.capture_fullscreen", comment: ""), action: #selector(captureFullScreen), keyEquivalent: "")
        fullScreenItem.target = self
        menu.addItem(fullScreenItem)

        menu.addItem(NSMenuItem.separator())

        // "Reveal last screenshot" menu item - enabled only if there's a recent capture
        let revealItem = NSMenuItem(title: NSLocalizedString("menu.show_last", comment: ""), action: #selector(revealLastScreenshot), keyEquivalent: "")
        revealItem.target = self
        revealItem.isEnabled = (lastScreenshotPath != nil)
        menu.addItem(revealItem)

        // History Submenu
        let historyMenu = NSMenu()
        let historyItem = NSMenuItem(title: NSLocalizedString("menu.history", comment: ""), action: nil, keyEquivalent: "")
        historyItem.submenu = historyMenu

        if #available(macOS 11.0, *) {
            historyItem.image = NSImage(systemSymbolName: "clock", accessibilityDescription: nil)
        }

        let history = AppSettings.shared.captureHistory

        if history.isEmpty {
            let emptyItem = NSMenuItem(title: NSLocalizedString("menu.history.empty", comment: ""), action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            historyMenu.addItem(emptyItem)
        } else {
            for path in history {
                let filename = (path as NSString).lastPathComponent
                let item = NSMenuItem(title: filename, action: #selector(copyFromHistory(_:)), keyEquivalent: "")
                item.representedObject = path
                item.target = self
                historyMenu.addItem(item)
            }

            historyMenu.addItem(NSMenuItem.separator())
            let clearItem = NSMenuItem(title: NSLocalizedString("menu.history.clear", comment: ""), action: #selector(clearHistory), keyEquivalent: "")
            clearItem.target = self
            historyMenu.addItem(clearItem)
        }

        menu.addItem(historyItem)

        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(title: NSLocalizedString("menu.preferences", comment: ""), action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        #if !APPSTORE
        // Check for Updates... (only for direct distribution, not App Store)
        let checkUpdatesItem = NSMenuItem(
            title: NSLocalizedString("menu.check_updates", comment: "Check for Updates..."),
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = self
        menu.addItem(checkUpdatesItem)
        #endif

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: NSLocalizedString("menu.quit", comment: ""), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        print("✅ Menu créé avec succès avec \(menu.items.count) éléments")

        return menu
    }

    @objc func takeScreenshot() {
        requestScreenRecordingIfNeeded { [weak self] in
            self?.performAreaCapture(source: .menuBar)
        }
    }

    @objc func captureFullScreen() {
        requestScreenRecordingIfNeeded { [weak self] in
            self?.performFullScreenCapture(source: .menuBar)
        }
    }

    @objc func handleHotKeyPressed() {
        print("⚡️ [APP] Hotkey notification received, triggering capture.")
        requestScreenRecordingIfNeeded { [weak self] in
            self?.performAreaCapture(source: .hotkey)
        }
    }

    @objc func revealLastScreenshot() {
        guard let path = lastScreenshotPath else {
            print("⚠️ Aucune capture récente")
            return
        }

        // Verify file still exists
        guard FileManager.default.fileExists(atPath: path) else {
            print("⚠️ Fichier introuvable: \(path)")
            // Reset lastScreenshotPath since file doesn't exist
            lastScreenshotPath = nil
            // Show alert
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("error.file_not_found.title", comment: "")
            alert.informativeText = NSLocalizedString("error.file_not_found.message", comment: "")
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        print("📁 [MENU] Ouverture du Finder: \(path)")
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }

    @objc func copyFromHistory(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }

        guard FileManager.default.fileExists(atPath: path) else {
            print("⚠️ [HISTORY] File not found: \(path)")
            return
        }

        guard let image = NSImage(contentsOfFile: path) else {
            print("⚠️ [HISTORY] Failed to load image from: \(path)")
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        pasteboard.setString(path, forType: .string)

        // Play sound for feedback
        if AppSettings.shared.playSoundOnCapture {
            NSSound(named: "Pop")?.play()
        }

        // Show small notification/feedback
        DynamicIslandManager.shared.show(message: "Copied", duration: 1.5)
    }

    @objc func clearHistory() {
        AppSettings.shared.clearHistory()
    }

    @objc func openPreferences() {
        // Si la fenêtre existe déjà, la mettre au premier plan
        if let window = preferencesWindow {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        // Créer la fenêtre de préférences
        let settingsView = SettingsView()
            .environmentObject(AppSettings.shared)

        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = NSLocalizedString("window.preferences", comment: "")
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")
        window.isReleasedWhenClosed = false

        // Gérer la fermeture de la fenêtre
        let delegate = PreferencesWindowDelegate { [weak self] in
            self?.preferencesWindow = nil
            self?.preferencesWindowDelegate = nil
        }
        self.preferencesWindowDelegate = delegate
        window.delegate = delegate

        self.preferencesWindow = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    #if !APPSTORE
    @objc func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
    #endif

    @objc func quit() {
        // Fermer toutes les fenêtres ouvertes
        preferencesWindow?.close()
        preferencesWindow = nil

        // Cleanup full screen service if needed

        // Nettoyer l'icône de la barre de menu
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }

        // Terminer l'application (le raccourci reste actif)
        NSApplication.shared.terminate(nil)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 [DELEGATE] willPresent appelé - notification à afficher")
        print("🔔 [DELEGATE] Titre: \(notification.request.content.title)")
        print("🔔 [DELEGATE] Body: \(notification.request.content.body)")

        if #available(macOS 12.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.banner])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let filePath = response.notification.request.content.userInfo["filePath"] as? String {
            print("🖱️ [DELEGATE] Clic sur notification - ouverture du fichier: \(filePath)")
            NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: "")
        }
        completionHandler()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // HotKeyManager cleans itself up via deinit, so we don't need to call stopMonitoring.
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }

    func requestNotificationPermission() {
        print("🔔 [APP] Requesting notification permission...")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ [APP] Notification permission error: \(error)")
            }
            print(granted ? "✅ [APP] Notification permission granted" : "⚠️ [APP] Notification permission denied")
        }
    }

#if DEBUG
    func testNotification() {
        print("🧪 [TEST] Envoi d'une notification de test au démarrage...")

        let content = UNMutableNotificationContent()
        content.title = "PastScreen - Test"
        content.body = "L'app a démarré avec succès"
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        print("🧪 [TEST] Notification de test envoyée")
    }
#endif

    // REMOVED: Auto-permission request functions
    // Permissions are now ONLY requested via Onboarding
    // This prevents popup chaos on first launch

    private func requestAllPermissions() {
        print("🔐 [APP] Requesting all necessary permissions...")

        // Check current status of all permissions
        permissionManager.checkAllPermissions()

        // Request Screen Recording permission
        permissionManager.requestPermission(.screenRecording) { granted in
            if !granted {
                print("⚠️ [APP] Screen Recording not authorized")
            }
        }

        // Request Accessibility permission (for global hotkeys)
        permissionManager.requestPermission(.accessibility) { granted in
            if !granted {
                print("⚠️ [APP] Accessibility not authorized - global hotkeys may not work")
            }
        }

        // Check if any permissions are missing after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            let missing = self.permissionManager.getMissingPermissions()
            if !missing.isEmpty {
                print("⚠️ [APP] Missing permissions: \(missing.map { $0.rawValue }.joined(separator: ", "))")
                // Only show alert if Screen Recording is missing (critical)
                if missing.contains(.screenRecording) {
                    self.permissionManager.showPermissionAlert(for: missing)
                }
            } else {
                print("✅ [APP] All permissions granted")
            }
        }
    }

    private func requestScreenRecordingIfNeeded(onGranted: @escaping () -> Void) {
        permissionManager.checkScreenRecordingPermission()
        if permissionManager.screenRecordingStatus == .authorized {
            onGranted()
            return
        }

        permissionManager.requestPermission(.screenRecording) { granted in
            DispatchQueue.main.async {
                if granted {
                    onGranted()
                } else {
                    self.permissionManager.showPermissionAlert(for: [.screenRecording])
                }
            }
        }
    }

    func performAreaCapture(source: CaptureTrigger = .menuBar) {
        guard let screenshotService = screenshotService else { return }
        print("🚀 [CAPTURE] Demande de capture area depuis: \(source.rawValue)")
        screenshotService.capturePreviousApp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak screenshotService] in
            screenshotService?.captureScreenshot()
        }
    }

    func performFullScreenCapture(source: CaptureTrigger = .menuBar) {
        guard let screenshotService = screenshotService else { return }
        print("🚀 [CAPTURE] Demande de capture plein écran depuis: \(source.rawValue)")
        screenshotService.capturePreviousApp()
        screenshotService.captureFullScreen()
    }

    // MARK: - Raccourci clavier global

    // All global hotkey logic has been refactored into the HotKeyManager class
    // to improve separation of concerns. The manager is initialized at launch
    // and communicates with AppDelegate via NotificationCenter.

    // MARK: - Dock Icon Management

    @objc func handleShowInDockChanged() {
        updateActivationPolicy()
    }

    func updateActivationPolicy() {
        let showInDock = settings.showInDock
        let currentPolicy = NSApp.activationPolicy()

        print("🔧 [DOCK] updateActivationPolicy() - showInDock: \(showInDock), currentPolicy: \(currentPolicy.rawValue)")

        if showInDock {
            NSApp.setActivationPolicy(.regular)
            print("✅ [DOCK] Mode normal activé (icône Dock + menu bar)")
        } else {
            NSApp.setActivationPolicy(.accessory)
            print("✅ [DOCK] Mode menu bar uniquement activé (pas de Dock)")
        }

        let newPolicy = NSApp.activationPolicy()
        print("🔧 [DOCK] Nouvelle policy: \(newPolicy.rawValue)")
    }
}

// MARK: - Preferences Window Delegate

class PreferencesWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
