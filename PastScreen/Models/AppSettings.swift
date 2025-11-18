//
//  AppSettings.swift
//  PastScreen
//
//  Settings management with UserDefaults persistence
//

import Foundation
import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var saveToFile: Bool {
        didSet {
            UserDefaults.standard.set(saveToFile, forKey: "saveToFile")
        }
    }

    @Published var saveFolderPath: String {
        didSet {
            UserDefaults.standard.set(saveFolderPath, forKey: "saveFolderPath")
            ensureFolderExists()
        }
    }

    @Published var imageFormat: String {
        didSet {
            UserDefaults.standard.set(imageFormat, forKey: "imageFormat")
        }
    }

    @Published var playSoundOnCapture: Bool {
        didSet {
            UserDefaults.standard.set(playSoundOnCapture, forKey: "playSoundOnCapture")
        }
    }

    @Published var globalHotkeyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(globalHotkeyEnabled, forKey: "globalHotkeyEnabled")
        }
    }

    @Published var showInDock: Bool {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: "showInDock")
            // Post notification to update activation policy
            NotificationCenter.default.post(name: .showInDockChanged, object: nil)
        }
    }

    @Published var autoCheckUpdates: Bool {
        didSet {
            UserDefaults.standard.set(autoCheckUpdates, forKey: "autoCheckUpdates")
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            LaunchAtLoginManager.shared.setEnabled(launchAtLogin)
        }
    }

    private init() {
        // Load saved values or use defaults
        self.saveToFile = UserDefaults.standard.object(forKey: "saveToFile") as? Bool ?? true  // Changed default to true

        // Default to temp directory (cleared on reboot) for "jetable" workflow
        self.saveFolderPath = UserDefaults.standard.string(forKey: "saveFolderPath") ?? (NSTemporaryDirectory() + "PastScreen/")

        self.imageFormat = UserDefaults.standard.string(forKey: "imageFormat") ?? "png"
        self.playSoundOnCapture = UserDefaults.standard.object(forKey: "playSoundOnCapture") as? Bool ?? true
        self.globalHotkeyEnabled = UserDefaults.standard.object(forKey: "globalHotkeyEnabled") as? Bool ?? true
        self.showInDock = UserDefaults.standard.object(forKey: "showInDock") as? Bool ?? true
        self.autoCheckUpdates = UserDefaults.standard.object(forKey: "autoCheckUpdates") as? Bool ?? true  // Default: auto-check enabled
        self.launchAtLogin = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? false  // Default: disabled

        ensureFolderExists()
    }

    func ensureFolderExists() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: saveFolderPath) {
            try? fileManager.createDirectory(atPath: saveFolderPath, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func selectFolder() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Sélectionner"

        if panel.runModal() == .OK {
            if let url = panel.url {
                return url.path + "/"
            }
        }
        return nil
    }

    func clearSaveFolder() {
        let fileManager = FileManager.default
        guard let items = try? fileManager.contentsOfDirectory(atPath: saveFolderPath) else { return }

        for item in items {
            let itemPath = saveFolderPath + item
            try? fileManager.removeItem(atPath: itemPath)
        }
    }
}
