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

        // Hide all selection windows
        window.hide()

        // Delay cleanup to avoid crash (window might have active references)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.selectionWindow = nil
            print("✅ [SELECTION] Window cleaned up")
        }

        // Perform capture with selected rectangle
        performCapture(rect: rect)
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
    
    // Traitement unifié de l'image capturée
    private func handleCapturedImage(_ image: NSImage) {
        print("🎨 [CLIPBOARD] Traitement de l'image: \(image.size)")

        // Son
        if AppSettings.shared.playSoundOnCapture {
            NSSound(named: "Grab")?.play()
        }

        // Presse-papier - TOUJOURS copier pour l'instant
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // Convertir en TIFF pour meilleure compatibilité
        guard let tiffData = image.tiffRepresentation else {
            print("❌ [CLIPBOARD] Impossible de convertir en TIFF")
            return
        }

        // Écrire dans le clipboard avec plusieurs formats pour compatibilité
        pasteboard.setData(tiffData, forType: .tiff)

        if let pngData = NSBitmapImageRep(data: tiffData)?.representation(using: .png, properties: [:]) {
            pasteboard.setData(pngData, forType: .png)
        }

        print("✅ [CLIPBOARD] Image copiée au presse-papier (TIFF + PNG)")

        // Sauvegarde
        var filePath: String? = nil
        if AppSettings.shared.saveToFile {
            filePath = saveToFileAndGetPath(image: image)
        }

        // Notification
        showSuccessNotification(filePath: filePath)
    }
    
    private func saveImageToFile(_ image: NSImage) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            print("❌ [SIMPLE] Impossible de convertir l'image")
            return
        }
        
        let format: NSBitmapImageRep.FileType = AppSettings.shared.imageFormat == "jpeg" ? .jpeg : .png
        let ext = AppSettings.shared.imageFormat == "jpeg" ? "jpg" : "png"
        
        guard let data = bitmap.representation(using: format, properties: [:]) else {
            print("❌ [SIMPLE] Impossible d'encoder l'image")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "PastScreen_\(timestamp).\(ext)"
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ [SIMPLE] Sauvé: \(fileURL.path)")
        } catch {
            print("❌ [SIMPLE] Erreur sauvegarde: \(error)")
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

    /// Détecte si l'app est en mode .accessory (menu bar only)
    private func showSuccessNotification(filePath: String?) {
        // 1. Notification macOS classique
        let notification = UNMutableNotificationContent()
        notification.title = "PastScreen"
        notification.body = NSLocalizedString("notification.screenshot_saved", comment: "")
        notification.sound = .default

        // Ajouter le chemin du fichier pour pouvoir l'ouvrir au clic
        if let filePath = filePath {
            notification.userInfo = ["filePath": filePath]
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notification,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)

        // 2. "Saved" dans la menu bar pendant 3 secondes
        DynamicIslandManager.shared.show(message: "Saved", duration: 3.0)
    }

    private func performCapture(rect: CGRect) {
        print("🎯 [CAPTURE] Début de la capture pour la région: \(rect)")

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
                let cgImage = try await self.captureWithScreenCaptureKit(rect: rect)
                let nsImage = NSImage(cgImage: cgImage, size: rect.size)

                print("✅ [CAPTURE] Capture ScreenCaptureKit réussie - Taille: \(nsImage.size)")
                await self.handleSuccessfulCapture(image: nsImage)

            } catch {
                print("❌ [CAPTURE] ScreenCaptureKit a échoué: \(error.localizedDescription)")

                DispatchQueue.main.async { [weak self] in
                    self?.showErrorNotification(error: error)
                }
            }
        }
    }
    
    // Nouvelle méthode avec ScreenCaptureKit
    private func captureWithScreenCaptureKit(rect: CGRect) async throws -> CGImage {
        return try await captureScreenRegion(rect: rect)
    }
    
    // Gestion commune du succès
    @MainActor
    private func handleSuccessfulCapture(image: NSImage) {
        // Play capture sound if enabled
        if AppSettings.shared.playSoundOnCapture {
            if let sound = NSSound(named: NSSound.Name("Glass")) {
                sound.play()
            } else if let fallback = NSSound(named: NSSound.Name("Pop")) {
                fallback.play()
            }
        }

        // Copy to clipboard if enabled
        if AppSettings.shared.copyToClipboard {
            print("📋 [CAPTURE] Copie vers le presse-papier...")
            self.copyToClipboard(image: image)
        }

        // Save to file if enabled
        var filePath: String? = nil
        if AppSettings.shared.saveToFile {
            print("💾 [CAPTURE] Sauvegarde vers fichier...")
            filePath = self.saveToFileAndGetPath(image: image)
        }

        // Show notification and visual feedback
        self.showSuccessNotification(filePath: filePath)
    }

    private func captureScreenRegion(rect: CGRect) async throws -> CGImage {
        print("🖥️ [ScreenCaptureKit] Capture région: \(rect)")
        
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
            
            // 2. Trouver l'écran principal
            guard let mainDisplay = content.displays.first else {
                throw NSError(domain: "ScreenshotService", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "Aucun écran disponible"
                ])
            }
            
            print("✅ [ScreenCaptureKit] Écran principal ID: \(mainDisplay.displayID)")
            
            // 3. Créer le filtre de contenu (capture tout l'écran, puis on crop)
            let filter = SCContentFilter(display: mainDisplay, excludingWindows: [])
            
            // 4. Configuration simple et robuste
            let config = SCStreamConfiguration()
            config.width = Int(rect.width)
            config.height = Int(rect.height)
            config.sourceRect = rect  // ScreenCaptureKit s'occupe des coordonnées
            config.scalesToFit = false
            config.showsCursor = false
            config.captureResolution = .best
            
            print("⚙️ [ScreenCaptureKit] Config: \(config.width)x\(config.height), sourceRect: \(config.sourceRect)")
            
            // 5. Capture avec l'API officielle
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
    private func copyToClipboard(image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let appCategory = detectFrontmostApp()

        switch appCategory {
        case .codeEditor:
            // Code editors prefer file paths for Markdown linking
            if let imagePath = saveToFileAndGetPath(image: image) {
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
            print("✅ [CLIPBOARD] Image data copied for browser/design tool")

        case .unknown:
            // Unknown apps: write BOTH formats for maximum compatibility
            pasteboard.writeObjects([image])
            if let imagePath = saveToFileAndGetPath(image: image) {
                pasteboard.setString(imagePath, forType: .string)
                print("✅ [CLIPBOARD] Both image data AND file path copied (unknown app)")
            } else {
                print("✅ [CLIPBOARD] Image data copied (file save failed)")
            }
        }
    }

    /// Save image to file and return the path (for file path clipboard)
    private func saveToFileAndGetPath(image: NSImage) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

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

    private func saveToFile(image: NSImage) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return
        }

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
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "Screenshot-\(timestamp).\(fileExtension)"

        // Utiliser le dossier temporaire si pas de dossier personnalisé
        let savePath: String
        if AppSettings.shared.saveFolderPath.isEmpty || AppSettings.shared.saveFolderPath == NSHomeDirectory() + "/Desktop/" {
            // Utiliser le dossier temporaire du système
            savePath = NSTemporaryDirectory() + filename
        } else {
            AppSettings.shared.ensureFolderExists()
            savePath = AppSettings.shared.saveFolderPath + filename
        }

        try? data.write(to: URL(fileURLWithPath: savePath))
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
