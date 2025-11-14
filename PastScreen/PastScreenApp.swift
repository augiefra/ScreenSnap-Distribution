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
import Sparkle

// Notification names
extension Notification.Name {
    static let screenshotCaptured = Notification.Name("screenshotCaptured")
    static let showInDockChanged = Notification.Name("showInDockChanged")
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

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?  // Référence persistante au menu
    var screenshotService: ScreenshotService?
    var preferencesWindow: NSWindow?
    var preferencesWindowDelegate: PreferencesWindowDelegate?  // Strong reference
    private var enforcingDockPreference = false
    private var hasShownDockWarning = false
    private var hasPromptedAccessibility = false
    private var hasPromptedScreenRecording = false

    // Services
    var permissionManager = PermissionManager.shared

    // Sparkle auto-updater
    private var updaterController: SPUStandardUpdaterController?

    // Pour le raccourci clavier global
    var globalEventMonitor: Any?
    var settings = AppSettings.shared
    private var settingsObserver: AnyCancellable?

    // Track last screenshot for "Reveal in Finder" menu item
    var lastScreenshotPath: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("🎯 [APP] ====== APPLICATION DID FINISH LAUNCHING ======")
        // Vérifier qu'une seule instance tourne (temporairement désactivé pour test)
        // if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "").count > 1 {
        //     print("Une autre instance de PastScreen est déjà en cours d'exécution")
        //     NSApp.terminate(nil)
        //     return
        // }

        // Setup notification center delegate first
        UNUserNotificationCenter.current().delegate = self

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

        // Request permission for system notifications
        requestNotificationPermission()

        #if DEBUG
        testNotification()
        #endif

        // Configurer le raccourci clavier global Option + Cmd + S
        setupGlobalHotkey()
        
        // Observer les changements de settings pour le raccourci clavier
        setupSettingsObserver()

        // Vérifier immédiatement l'état des permissions critiques
        permissionManager.checkAllPermissions()
        requestCriticalPermissionsIfNeeded()

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

        // Initialize Sparkle auto-updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        NSLog("✅ [SPARKLE] Auto-updater initialized")
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

        menu.addItem(NSMenuItem.separator())

        let prefsItem = NSMenuItem(title: NSLocalizedString("menu.preferences", comment: ""), action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        // Check for Updates...
        let checkUpdatesItem = NSMenuItem(
            title: NSLocalizedString("menu.check_updates", comment: "Check for Updates..."),
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = self
        menu.addItem(checkUpdatesItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: NSLocalizedString("menu.quit", comment: ""), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        print("✅ Menu créé avec succès avec \(menu.items.count) éléments")

        return menu
    }

    @objc func takeScreenshot() {
        requestScreenRecordingIfNeeded { [weak self] in
            self?.performAreaCapture()
        }
    }

    @objc func captureFullScreen() {
        requestScreenRecordingIfNeeded { [weak self] in
            self?.performFullScreenCapture()
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

    @objc func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }

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
        // Nettoyage final
        settingsObserver?.cancel()
        removeGlobalHotkey()
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
        print("🧪 [TEST] Delegate configuré: \(UNUserNotificationCenter.current().delegate != nil)")
    }
#endif

    private func requestCriticalPermissionsIfNeeded() {
        if permissionManager.notificationStatus == .notDetermined {
            requestNotificationPermission()
        }

        ensureAccessibilityPermissionIfNeeded()

        if permissionManager.screenRecordingStatus != .authorized && !hasPromptedScreenRecording {
            hasPromptedScreenRecording = true
            permissionManager.requestPermission(.screenRecording) { granted in
                if !granted {
                    DispatchQueue.main.async {
                        self.permissionManager.showPermissionAlert(for: [.screenRecording])
                    }
                }
            }
        }
    }

    private func ensureAccessibilityPermissionIfNeeded() {
        guard settings.globalHotkeyEnabled else { return }
        if permissionManager.accessibilityStatus == .authorized { return }
        if hasPromptedAccessibility { return }
        hasPromptedAccessibility = true
        permissionManager.requestPermission(.accessibility) { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.permissionManager.showPermissionAlert(for: [.accessibility])
                }
            }
        }
    }

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

    private func performAreaCapture() {
        guard let screenshotService = screenshotService else { return }
        screenshotService.capturePreviousApp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak screenshotService] in
            screenshotService?.captureScreenshot()
        }
    }

    private func performFullScreenCapture() {
        guard let screenshotService = screenshotService else { return }
        screenshotService.capturePreviousApp()
        screenshotService.captureFullScreen()
    }
    
    // MARK: - Raccourci clavier global
    
    func setupSettingsObserver() {
        // Observer les changements du setting globalHotkeyEnabled
        settingsObserver = settings.$globalHotkeyEnabled.sink { [weak self] enabled in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if enabled {
                    self.ensureAccessibilityPermissionIfNeeded()
                    self.setupGlobalHotkey()
                } else {
                    self.removeGlobalHotkey()
                }
            }
        }
    }
    
    func setupGlobalHotkey() {
        // Ne pas créer plusieurs moniteurs
        removeGlobalHotkey()
        
        // Vérifier si le raccourci est activé dans les settings
        guard settings.globalHotkeyEnabled else {
            print("Raccourci clavier global désactivé dans les préférences")
            return
        }
        
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️ [HOTKEY] L'application n'a pas les autorisations d'accessibilité!")
            print("⚠️ [HOTKEY] Le raccourci global ne fonctionnera PAS sans cette autorisation")
            ensureAccessibilityPermissionIfNeeded()
            return
        }
        
        // Créer le moniteur d'événements global pour Option + Cmd + S
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Vérifier que Option et Command sont pressés (en ignorant les autres flags système)
            let hasOption = event.modifierFlags.contains(.option)
            let hasCommand = event.modifierFlags.contains(.command)
            let hasShift = event.modifierFlags.contains(.shift)
            let hasControl = event.modifierFlags.contains(.control)

            // Option + Command pressés, mais PAS Shift ou Control
            let isCorrectModifiers = hasOption && hasCommand && !hasShift && !hasControl

            // Code 1 pour 'S' (QWERTY layout)
            let isS = event.keyCode == 1 || event.characters?.lowercased() == "s"

            if isCorrectModifiers && isS {
                print("🎯 [HOTKEY] Raccourci ⌥⌘S détecté!")
                print("   keyCode: \(event.keyCode), characters: \(event.characters ?? "nil")")

                self?.requestScreenRecordingIfNeeded {
                    self?.performAreaCapture()
                }
            }
        }

        print("✅ [HOTKEY] Raccourci clavier global ⌥⌘S configuré avec succès")
    }
    
    func removeGlobalHotkey() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
            print("❌ Raccourci clavier global supprimé")
        }
    }

    // MARK: - Dock Icon Management

    @objc func handleShowInDockChanged() {
        updateActivationPolicy()
    }

    func updateActivationPolicy() {
        let showInDock = settings.showInDock

        if showInDock {
            NSApp.setActivationPolicy(.regular)
            hasShownDockWarning = false
            print("✅ [DOCK] Mode normal activé (icône Dock + menu bar)")
        } else {
            if !hasShownDockWarning {
                hasShownDockWarning = true
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Notifications Apple indisponibles sans icône Dock"
                    alert.informativeText = "Les notifications système et les sons natifs nécessitent que PastScreen apparaisse dans le Dock. L'option sera réactivée automatiquement."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }

            guard !enforcingDockPreference else { return }
            enforcingDockPreference = true
            settings.showInDock = true
            enforcingDockPreference = false
            NSApp.setActivationPolicy(.regular)
            print("⚠️ [DOCK] Icône Dock réactivée automatiquement pour permettre les notifications Apple")
        }
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
