//
//  ScreenshotService.swift
//  ScreenSnap
//
//  Screenshot capture service with Liquid Glass selection UI
//

import Foundation
import AppKit
import CoreGraphics
import SwiftUI
import UserNotifications
import ScreenCaptureKit

class ScreenshotService: NSObject {
    private var captureTask: Process?

    override init() {
        super.init()
        setupNotificationObservers()
    }

    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenshotRequest),
            name: .screenshotRequested,
            object: nil
        )
    }

    @objc func handleScreenshotRequest() {
        captureScreenshot()
    }

    func captureScreenshot() {
        print("🎬 [SERVICE] Début de la capture avec screencapture natif...")

        // Créer un fichier temporaire
        let timestamp = Date().timeIntervalSince1970
        let filename = "ScreenSnap-\(Int(timestamp)).png"
        let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)

        // Lancer screencapture en mode interactif
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = [
            "-i",           // Interactive mode (selection)
            "-o",           // No shadow
            tempPath        // Output file
        ]

        process.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                self?.handleScreencaptureCompletion(exitCode: process.terminationStatus, filePath: tempPath)
            }
        }

        do {
            try process.run()
            self.captureTask = process
            print("✅ [SERVICE] screencapture lancé - sélectionnez une zone")
        } catch {
            print("❌ [SERVICE] Erreur lancement screencapture: \(error)")
            showErrorAlert("Impossible de lancer la capture d'écran")
        }
    }

    // NEW: Full screen capture using native screencapture utility
    func captureFullScreen() {
        print("🎬 [SERVICE] Début de la capture plein écran avec screencapture natif...")

        // Créer un fichier temporaire
        let timestamp = Date().timeIntervalSince1970
        let filename = "ScreenSnap-FullScreen-\(Int(timestamp)).png"
        let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(filename)

        // Lancer screencapture pour capturer l'écran principal
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = [
            "-m",           // Capture main display
            "-o",           // No shadow
            tempPath        // Output file
        ]

        process.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                self?.handleScreencaptureCompletion(exitCode: process.terminationStatus, filePath: tempPath)
            }
        }

        do {
            try process.run()
            self.captureTask = process
            print("✅ [SERVICE] screencapture lancé pour écran complet")
        } catch {
            print("❌ [SERVICE] Erreur lancement screencapture: \(error)")
            showErrorAlert("Impossible de lancer la capture d'écran")
        }
    }

    private func handleScreencaptureCompletion(exitCode: Int32, filePath: String) {
        captureTask = nil

        // Si l'utilisateur annule (ESC), exitCode = 1
        guard exitCode == 0 else {
            print("❌ [SERVICE] Capture annulée (exit code: \(exitCode))")
            try? FileManager.default.removeItem(atPath: filePath)
            return
        }

        // Vérifier que le fichier existe
        guard FileManager.default.fileExists(atPath: filePath) else {
            print("❌ [SERVICE] Fichier de capture introuvable")
            return
        }

        print("✅ [SERVICE] Capture réussie: \(filePath)")

        // Copier le PATH du fichier au clipboard (comme cc-screenshot.sh)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(filePath, forType: .string)
        print("📋 [SERVICE] Chemin copié au clipboard: \(filePath)")

        // Jouer le son "Glass" (comme dans le script bash)
        if AppSettings.shared.playSoundOnCapture {
            NSSound(named: "Glass")?.play()
        }

        // Pilule dans la barre de menus
        print("🔵 [SERVICE] Affichage de la pilule...")
        DynamicIslandManager.shared.show(message: "Saved", duration: 3.0)

        // Notifier l'app delegate pour mettre à jour lastScreenshotPath
        NotificationCenter.default.post(
            name: .screenshotCaptured,
            object: nil,
            userInfo: ["filePath": filePath]
        )

        // Notification native macOS (comme le script bash)
        print("🔔 [SERVICE] Envoi de la notification...")
        showNativeNotification(filePath: filePath)
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
        if AppSettings.shared.saveToFile {
            saveImageToFile(image)
        }

        // Notification
        showSuccessNotification()
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
        let filename = "ScreenSnap_\(timestamp).\(ext)"
        
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
        alert.messageText = "Erreur de capture"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
    
    private func showNativeNotification(filePath: String) {
        // Note: UNUserNotification doesn't work for .accessory apps
        // The DynamicIslandManager pill provides sufficient feedback
        let notification = UNMutableNotificationContent()
        notification.title = "📸 Screenshot Ready"
        notification.body = "Click to reveal in Finder"
        notification.sound = nil  // Le son est déjà joué
        notification.userInfo = ["filePath": filePath]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notification,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [NOTIF] UNUserNotification error: \(error)")
            } else {
                print("✅ [NOTIF] UNUserNotification sent (won't display for .accessory apps)")
            }
        }

        // Visual feedback is provided by:
        // 1. DynamicIslandManager pill ("✓ Saved" in menu bar) - PRIMARY
        // 2. Screen flash effect
        // 3. "Glass" sound
        print("ℹ️ [NOTIF] Visual feedback via DynamicIslandManager pill")
    }

    private func showSuccessNotification() {
        let notification = UNMutableNotificationContent()
        notification.title = "ScreenSnap"
        notification.body = "Capture d'écran réussie !"
        notification.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notification,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func performCapture(rect: CGRect) {
        print("🎯 [CAPTURE] Début de la capture pour la région: \(rect)")
        
        // Vérifier que le rectangle est valide
        guard rect.width > 0 && rect.height > 0 else {
            print("❌ [CAPTURE] Rectangle de capture invalide: \(rect)")
            DispatchQueue.main.async {
                self.showErrorNotification(error: NSError(domain: "ScreenshotService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Rectangle de sélection invalide"]))
            }
            return
        }
        
        Task {
            do {
                // Essayer d'abord avec ScreenCaptureKit (moderne)
                let cgImage = try await captureWithScreenCaptureKit(rect: rect)
                let nsImage = NSImage(cgImage: cgImage, size: rect.size)
                
                print("✅ [CAPTURE] Capture ScreenCaptureKit réussie - Taille: \(nsImage.size)")
                await handleSuccessfulCapture(image: nsImage)
                
            } catch {
                print("❌ [CAPTURE] ScreenCaptureKit a échoué: \(error.localizedDescription)")

                DispatchQueue.main.async {
                    self.showErrorNotification(error: error)
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
        // Play sound if enabled - Son "Glass" comme le script bash
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
        if AppSettings.shared.saveToFile {
            print("💾 [CAPTURE] Sauvegarde vers fichier...")
            self.saveToFile(image: image)
        }

        // Show notification moderne
        self.showModernNotification()
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

    private func copyToClipboard(image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
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

    private func showModernNotification() {
        // Note: UNUserNotification doesn't work for .accessory apps
        let content = UNMutableNotificationContent()
        content.title = "📸 ScreenSnap"
        content.body = "Capture d'écran enregistrée"
        content.sound = nil
        content.categoryIdentifier = "SCREENSHOT_CAPTURE"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)

        // Visual feedback via DynamicIslandManager pill + screen flash
        showScreenFlash()
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
    
    private func showScreenFlash() {
        // Créer un flash blanc rapide sur tous les écrans
        var flashWindows: [NSWindow] = []
        
        for screen in NSScreen.screens {
            let flashWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            flashWindow.backgroundColor = .white
            flashWindow.level = .screenSaver + 1
            flashWindow.isOpaque = false
            flashWindow.ignoresMouseEvents = true
            flashWindow.hasShadow = false
            flashWindow.alphaValue = 0.8
            
            flashWindows.append(flashWindow)
            flashWindow.makeKeyAndOrderFront(nil)
        }
        
        // Animation de flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in flashWindows {
                window.animator().alphaValue = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                for window in flashWindows {
                    window.close()
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
