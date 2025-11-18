//
//  ScreenshotService.swift
//  PastScreen
//
//  Screenshot capture service with Liquid Glass selection UI
//

import Foundation
import AppKit
import CoreGraphics
import SwiftUI
import UserNotifications
import ScreenCaptureKit

// MARK: - App Category Detection

enum AppCategory {
    case codeEditor
    case webBrowser
    case designTool
    case unknown
}

class ScreenshotService: NSObject, SelectionWindowDelegate {
    private var previousApp: NSRunningApplication? // Store app that was active before capture
    private var selectionWindow: SelectionWindow? // Custom selection window

    // Bundle IDs of known applications
    private let appCategoryMap: [String: AppCategory] = [
        // Code Editors
        "com.microsoft.VSCode": .codeEditor,
        "com.microsoft.VSCodeInsiders": .codeEditor,
        "dev.zed.Zed": .codeEditor,
        "com.todesktop.230313mzl4w4u92": .codeEditor, // Cursor
        "com.sublimetext.4": .codeEditor,
        "com.apple.dt.Xcode": .codeEditor,
        "com.jetbrains.intellij": .codeEditor,
        "com.jetbrains.pycharm": .codeEditor,
        "com.github.atom": .codeEditor,
        "com.uranusjr.macdown": .codeEditor,
        "abnerworks.Typora": .codeEditor,
        "md.obsidian": .codeEditor,

        // Web Browsers
        "com.apple.Safari": .webBrowser,
        "com.apple.SafariTechnologyPreview": .webBrowser,
        "com.google.Chrome": .webBrowser,
        "com.google.Chrome.canary": .webBrowser,
        "org.mozilla.firefox": .webBrowser,
        "org.mozilla.firefoxdeveloperedition": .webBrowser,
        "com.microsoft.edgemac": .webBrowser,
        "com.microsoft.edgemac.Dev": .webBrowser,
        "com.brave.Browser": .webBrowser,
        "com.brave.Browser.dev": .webBrowser,
        "com.operasoftware.Opera": .webBrowser,
        "com.operasoftware.OperaGX": .webBrowser,
        "company.thebrowser.Browser": .webBrowser, // Arc
        "company.thebrowser.dia": .webBrowser, // DIA
        "com.vivaldi.Vivaldi": .webBrowser,
        "org.chromium.Chromium": .webBrowser,
        "com.kagi.kagimacOS": .webBrowser, // Orion
        "com.pushplaylabs.Sidekick": .webBrowser,
        "com.maxthon.mac.Maxthon": .webBrowser,
        "com.microsoft.Outlook": .webBrowser,

        // Design & Communication Tools
        "com.figma.Desktop": .designTool,
        "com.tinyspeck.slackmacgap": .designTool,
        "com.hnc.Discord": .designTool,
        "com.linear": .designTool,
        "notion.id": .designTool,
        "com.sketch.app": .designTool,
        "com.bohemiancoding.sketch3": .designTool,
        "com.adobe.PhotoshopCC": .designTool,
        "com.framerx.Framer": .designTool
    ]

    func captureScreenshot() {
        print("🎬 [SERVICE] Launching SelectionWindow for area capture...")

        // CRITICAL: Force cleanup of any existing selection window before creating new one
        // (prevents overlay windows from persisting if user takes multiple screenshots rapidly)
        if let existingWindow = selectionWindow {
            print("⚠️ [SERVICE] Cleaning up existing SelectionWindow before creating new one")
            existingWindow.hide()
            selectionWindow = nil
        }

        // Create and show custom selection window (one per screen for multi-monitor support)
        selectionWindow = SelectionWindow()
        selectionWindow?.selectionDelegate = self
        selectionWindow?.show()

        print("✅ [SERVICE] SelectionWindow displayed on all screens - select area or press ESC to cancel")
    }

    // NEW: Full screen capture using ScreenCaptureKit
    func captureFullScreen() {
        print("🎬 [SERVICE] Starting full screen capture with ScreenCaptureKit...")

        // Calculate combined frame covering all screens
        let screenFrame = NSScreen.screens.reduce(NSRect.zero) { $0.union($1.frame) }

        print("✅ [SERVICE] Capturing full screen area: \(screenFrame)")
        performCapture(rect: screenFrame)
    }

    // MARK: - SelectionWindowDelegate

    func selectionWindow(_ window: SelectionWindow, didSelectRect rect: CGRect) {
        print("📐 [SELECTION] User selected rect: \(rect)")

        // Get overlay window IDs BEFORE hiding (for ScreenCaptureKit exclusion)
        let overlayWindowIDs = window.getOverlayWindowIDs()
        print("🔢 [SELECTION] Got \(overlayWindowIDs.count) overlay window IDs for exclusion")

        // Hide all selection windows
        window.hide()

        // CRITICAL: Wait for windows to be visually hidden before capturing
        // ScreenCaptureKit captures everything on screen, including overlays
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }

            // Now perform capture with overlay windows excluded
            self.performCapture(rect: rect, excludeWindowIDs: overlayWindowIDs)

            // Cleanup window reference
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.selectionWindow = nil
                print("✅ [SELECTION] Window cleaned up")
            }
        }
    }

    func selectionWindowDidCancel(_ window: SelectionWindow) {
        print("❌ [SELECTION] User cancelled selection")

        // Hide all selection windows
        window.hide()

        // Delay cleanup to avoid crash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.selectionWindow = nil
            print("✅ [SELECTION] Window cleaned up after cancel")
        }
    }
    private func showErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("error.capture_error", comment: "")
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    // MARK: - Notification Routing

    /// Affiche une notification macOS native (toujours UNUserNotification)
    private func showSuccessNotification(filePath: String?) {
        let pathDescription = filePath ?? "nil"
        print("🔔 [NOTIF] showSuccessNotification appelée avec filePath: \(pathDescription)")

        let content = UNMutableNotificationContent()
        content.title = "PastScreen"
        content.body = NSLocalizedString("notification.screenshot_saved", comment: "")
        content.sound = nil  // conserver uniquement le son "Glass" joué avant la notification

        if let filePath = filePath {
            content.userInfo = ["filePath": filePath]
            print("🔔 [NOTIF] UserInfo configuré avec filePath")
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        // Send notification without changing activation policy
        // (avoids Dock icon flash that confuses users)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [NOTIF] Erreur UNUserNotification: \(error)")
            } else {
                print("✅ [NOTIF] UNUserNotification envoyée")
            }
        }

        DynamicIslandManager.shared.show(message: "Saved", duration: 3.0)
    }

    private func performCapture(rect: CGRect, excludeWindowIDs: [CGWindowID] = []) {
        print("🎯 [CAPTURE] Début de la capture pour la région: \(rect)")
        print("🚫 [CAPTURE] Excluding \(excludeWindowIDs.count) overlay windows from capture")

        // Vérifier que le rectangle est valide
        guard rect.width > 0 && rect.height > 0 else {
            print("❌ [CAPTURE] Rectangle de capture invalide: \(rect)")
            DispatchQueue.main.async { [weak self] in
                self?.showErrorNotification(error: NSError(domain: "ScreenshotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Rectangle de sélection invalide"]))
            }
            return
        }

        Task { [weak self] in
            guard let self = self else { return }

            do {
                // Essayer d'abord avec ScreenCaptureKit (moderne)
                let cgImage = try await self.captureWithScreenCaptureKit(rect: rect, excludeWindowIDs: excludeWindowIDs)

                print("✅ [CAPTURE] Capture ScreenCaptureKit réussie - Taille: \(cgImage.width)x\(cgImage.height)")
                await self.handleSuccessfulCapture(cgImage: cgImage, selectionRect: rect)

            } catch {
                print("❌ [CAPTURE] ScreenCaptureKit a échoué: \(error.localizedDescription)")

                DispatchQueue.main.async { [weak self] in
                    self?.showErrorNotification(error: error)
                }
            }
        }
    }

    // Nouvelle méthode avec ScreenCaptureKit
    private func captureWithScreenCaptureKit(rect: CGRect, excludeWindowIDs: [CGWindowID]) async throws -> CGImage {
        return try await captureScreenRegion(rect: rect, excludeWindowIDs: excludeWindowIDs)
    }

    // Gestion commune du succès
    @MainActor
    private func handleSuccessfulCapture(cgImage: CGImage, selectionRect: CGRect) {
        // Play capture sound if enabled
        if AppSettings.shared.playSoundOnCapture {
            if let sound = NSSound(named: NSSound.Name("Glass")) {
                sound.play()
            } else if let fallback = NSSound(named: NSSound.Name("Pop")) {
                fallback.play()
            }
        }

        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = selectionRect.size
        let nsImage = NSImage(size: selectionRect.size)
        nsImage.addRepresentation(rep)

        print("📋 [CAPTURE] Copie vers le presse-papier...")
        let clipboardFilePath = self.copyToClipboard(
            image: nsImage,
            cgImage: cgImage,
            pointSize: selectionRect.size
        )

        // Save to file if enabled (or reuse path already created for clipboard)
        var filePath: String? = clipboardFilePath
        if AppSettings.shared.saveToFile {
            if filePath == nil {
                print("💾 [CAPTURE] Sauvegarde vers fichier (préférence utilisateur)...")
                filePath = self.saveToFileAndGetPath(
                    cgImage: cgImage,
                    pointSize: selectionRect.size
                )
            } else {
                print("💾 [CAPTURE] Fichier déjà enregistré pour le clipboard, réutilisation du même chemin")
            }
        }

        if let filePath = filePath {
            NotificationCenter.default.post(name: .screenshotCaptured, object: nil, userInfo: ["filePath": filePath])
        }

        // Show notification and visual feedback
        self.showSuccessNotification(filePath: filePath)
    }

    private func captureScreenRegion(rect: CGRect, excludeWindowIDs: [CGWindowID]) async throws -> CGImage {
        print("🖥️ [ScreenCaptureKit] Capture région: \(rect)")
        print("🚫 [ScreenCaptureKit] Window IDs to exclude: \(excludeWindowIDs)")

        // Vérification de base du rectangle
        guard rect.width > 0 && rect.height > 0 else {
            throw NSError(domain: "ScreenshotService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Rectangle invalide: \(rect)"
            ])
        }

        do {
            // 1. Obtenir le contenu partageable
            let content = try await SCShareableContent.current
            print("✅ [ScreenCaptureKit] \(content.displays.count) écran(s) disponible(s)")

            // 2. Find NSScreen that contains the selection rect
            guard let nsScreen = NSScreen.screens.first(where: { $0.frame.intersects(rect) }) else {
                throw NSError(domain: "ScreenshotService", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "Aucun écran trouvé pour la zone sélectionnée"
                ])
            }

            // 3. Match NSScreen to SCDisplay by displayID
            let displayID = nsScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            let targetDisplay: SCDisplay
            if let matchedDisplay = content.displays.first(where: { $0.displayID == displayID }) {
                targetDisplay = matchedDisplay
                print("✅ [ScreenCaptureKit] Matched display ID: \(targetDisplay.displayID)")
            } else {
                print("⚠️ [ScreenCaptureKit] Display ID \(displayID) not found, using first display")
                guard let fallbackDisplay = content.displays.first else {
                    throw NSError(domain: "ScreenshotService", code: -3, userInfo: [
                        NSLocalizedDescriptionKey: "Aucun écran disponible"
                    ])
                }
                targetDisplay = fallbackDisplay
                print("✅ [ScreenCaptureKit] Using fallback display ID: \(targetDisplay.displayID)")
            }

            let screenFrame = nsScreen.frame
            // AppKit uses a global coordinate system origin at bottom-left,
            // but our SelectionWindow delivers a rect in global coordinates with the origin
            // still bottom-left yet user selection is visually referenced from the top-left
            // of each screen. ScreenCaptureKit expects the rect relative to the display's
            // coordinate space with origin top-left, so we need to flip the Y axis.
            let offsetX = rect.origin.x - screenFrame.origin.x
            let offsetY = rect.origin.y - screenFrame.origin.y
            let flippedY = screenFrame.size.height - offsetY - rect.size.height

            var rectInScreenPoints = CGRect(
                x: offsetX,
                y: flippedY,
                width: rect.width,
                height: rect.height
            )

            let screenBounds = CGRect(origin: .zero, size: screenFrame.size)
            var relativeRect = rectInScreenPoints
            if !screenBounds.contains(rectInScreenPoints) {
                print("⚠️ [ScreenCaptureKit] Selection extends outside screen bounds, clipping…")
                relativeRect = rectInScreenPoints.intersection(screenBounds)
                guard !relativeRect.isNull else {
                    throw NSError(domain: "ScreenshotService", code: -4, userInfo: [
                        NSLocalizedDescriptionKey: "Sélection hors de l'écran sélectionné"
                    ])
                }
                print("✂️ [ScreenCaptureKit] Relative rect after clipping: \(relativeRect)")
            }

            print("✅ [ScreenCaptureKit] Capturing from display ID: \(targetDisplay.displayID)")
            print("   Global rect: \(rect) on screen frame: \(screenFrame)")
            print("   Relative rect: \(relativeRect)")

            // 4. Convert window IDs to SCWindow objects for exclusion
            let excludeWindows = content.windows.filter { window in
                excludeWindowIDs.contains(CGWindowID(window.windowID))
            }
            print("🚫 [ScreenCaptureKit] Found \(excludeWindows.count) overlay windows to exclude")

            // 5. Créer le filtre de contenu (capture le BON écran, SAUF les overlays)
            let filter = SCContentFilter(display: targetDisplay, excludingWindows: excludeWindows)

            // 6. Determine backing scale factor (Retina = 2.0, non-Retina = 1.0)
            // Use the nsScreen we already found
            let scaleFactor = nsScreen.backingScaleFactor
            print("🔍 [ScreenCaptureKit] Backing scale factor: \(scaleFactor)x")

            // 7. Configuration avec résolution native (points × scale factor = pixels)
            let config = SCStreamConfiguration()
            config.width = Int(relativeRect.width * scaleFactor)  // Convert points to pixels
            config.height = Int(relativeRect.height * scaleFactor)  // Convert points to pixels
            config.sourceRect = relativeRect  // Relative to target display coordinates
            config.scalesToFit = false
            config.showsCursor = false
            config.captureResolution = .best

            print("⚙️ [ScreenCaptureKit] Config: \(config.width)x\(config.height) pixels (\(Int(relativeRect.width))x\(Int(relativeRect.height)) points × \(scaleFactor)), sourceRect (relative): \(config.sourceRect)")

            // 8. Capture avec l'API officielle
            let cgImage = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            print("✅ [ScreenCaptureKit] Capture réussie: \(cgImage.width)x\(cgImage.height)")
            return cgImage

        } catch let error as SCStreamError {
            print("❌ [ScreenCaptureKit] Erreur SCStream: \(error.localizedDescription)")

            // Gestion spécifique des erreurs ScreenCaptureKit
            switch error.code {
            case .userDeclined:
                throw NSError(domain: "ScreenshotService", code: -10, userInfo: [
                    NSLocalizedDescriptionKey: "Permission de capture d'écran refusée. Allez dans Préférences Système > Confidentialité et sécurité > Enregistrement d'écran."
                ])
            case .systemStoppedStream:
                throw NSError(domain: "ScreenshotService", code: -11, userInfo: [
                    NSLocalizedDescriptionKey: "Capture interrompue par le système"
                ])
            default:
                throw NSError(domain: "ScreenshotService", code: -12, userInfo: [
                    NSLocalizedDescriptionKey: "Erreur de capture: \(error.localizedDescription)"
                ])
            }

        } catch {
            print("❌ [ScreenCaptureKit] Erreur générale: \(error)")
            throw NSError(domain: "ScreenshotService", code: -13, userInfo: [
                NSLocalizedDescriptionKey: "Échec de la capture d'écran: \(error.localizedDescription)"
            ])
        }
    }

    // MARK: - Smart Clipboard Detection

    /// Capture the frontmost application BEFORE showing selection window
    func capturePreviousApp() {
        // Get the app that is currently active (before PastScreen becomes active)
        previousApp = NSWorkspace.shared.frontmostApplication
        if let app = previousApp, let bundleID = app.bundleIdentifier {
            let category = appCategoryMap[bundleID] ?? .unknown
            print("📱 [DETECTION] Captured previous app: \(app.localizedName ?? "Unknown")")
            print("   Bundle ID: \(bundleID)")
            print("   Category: \(category)")

            // If unknown, suggest adding it
            if category == .unknown {
                print("⚠️ [DETECTION] Unknown app! Add this bundle ID to appCategoryMap:")
                print("   \"\(bundleID)\": .webBrowser  // or .codeEditor or .designTool")
            }
        } else {
            print("⚠️ [DETECTION] Could not detect previous app")
        }
    }

    /// Detect the application category based on previously captured app
    private func detectFrontmostApp() -> AppCategory {
        guard let app = previousApp,
              let bundleID = app.bundleIdentifier else {
            print("⚠️ [CLIPBOARD] No previous app detected, using default behavior")
            return .unknown
        }

        let category = appCategoryMap[bundleID] ?? .unknown
        print("📱 [CLIPBOARD] Using previous app: \(app.localizedName ?? "Unknown") (\(bundleID)) → \(category)")
        return category
    }

    /// Copy image to clipboard with smart format detection
    @discardableResult
    private func copyToClipboard(
        image: NSImage,
        cgImage: CGImage,
        pointSize: CGSize
    ) -> String? {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let appCategory = detectFrontmostApp()
        var filePath: String? = nil

        switch appCategory {
        case .codeEditor:
            // Code editors prefer file paths for Markdown linking
            if let imagePath = saveToFileAndGetPath(cgImage: cgImage, pointSize: pointSize) {
                filePath = imagePath
                pasteboard.setString(imagePath, forType: .string)
                print("✅ [CLIPBOARD] File path copied for code editor: \(imagePath)")
            } else {
                // Fallback: write image if file save fails
                pasteboard.writeObjects([image])
                print("⚠️ [CLIPBOARD] File save failed, copied image data instead")
            }

        case .webBrowser, .designTool:
            // Browsers and design tools need actual image data
            pasteboard.writeObjects([image])
            if let imagePath = saveToFileAndGetPath(cgImage: cgImage, pointSize: pointSize) {
                filePath = imagePath
                pasteboard.setString(imagePath, forType: .string)
                print("✅ [CLIPBOARD] Image data copied for browser/design tool + file path available: \(imagePath)")
            } else {
                print("✅ [CLIPBOARD] Image data copied for browser/design tool (no path)")
            }

        case .unknown:
            // Unknown apps: write BOTH formats for maximum compatibility
            pasteboard.writeObjects([image])
            if let imagePath = saveToFileAndGetPath(cgImage: cgImage, pointSize: pointSize) {
                filePath = imagePath
                pasteboard.setString(imagePath, forType: .string)
                print("✅ [CLIPBOARD] Both image data AND file path copied (unknown app)")
            } else {
                print("✅ [CLIPBOARD] Image data copied (file save failed)")
            }
        }
        return filePath
    }

    /// Save image to file (with DPI metadata) and return the path
    private func saveToFileAndGetPath(
        cgImage: CGImage,
        pointSize: CGSize
    ) -> String? {
        let bitmapImage = NSBitmapImageRep(cgImage: cgImage)
        bitmapImage.size = pointSize

        let fileType: NSBitmapImageRep.FileType
        let fileExtension: String

        switch AppSettings.shared.imageFormat {
        case "jpeg":
            fileType = .jpeg
            fileExtension = "jpg"
        default:
            fileType = .png
            fileExtension = "png"
        }

        guard let data = bitmapImage.representation(using: fileType, properties: [:]) else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "Screenshot-\(timestamp).\(fileExtension)"

        let savePath: String
        if AppSettings.shared.saveFolderPath.isEmpty || AppSettings.shared.saveFolderPath == NSHomeDirectory() + "/Desktop/" {
            savePath = NSTemporaryDirectory() + filename
        } else {
            AppSettings.shared.ensureFolderExists()
            savePath = AppSettings.shared.saveFolderPath + filename
        }

        do {
            try data.write(to: URL(fileURLWithPath: savePath))
            return savePath
        } catch {
            print("❌ [CLIPBOARD] Failed to save file: \(error)")
            return nil
        }
    }

    private func showErrorNotification(error: Error) {
        print("🚨 Error: \(error.localizedDescription)")

        // For errors, show a proper alert dialog
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Screenshot Error"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
