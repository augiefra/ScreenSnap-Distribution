//
//  AppSettings.swift
//  ScreenSnap
//
//  Settings management with UserDefaults persistence
//

import Foundation
import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var copyToClipboard: Bool {
        didSet {
            UserDefaults.standard.set(copyToClipboard, forKey: "copyToClipboard")
        }
    }

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

    @Published var showDimensionsLabel: Bool {
        didSet {
            UserDefaults.standard.set(showDimensionsLabel, forKey: "showDimensionsLabel")
        }
    }

    @Published var enableAnnotations: Bool {
        didSet {
            UserDefaults.standard.set(enableAnnotations, forKey: "enableAnnotations")
        }
    }

    @Published var globalHotkeyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(globalHotkeyEnabled, forKey: "globalHotkeyEnabled")
        }
    }

    private init() {
        // Load saved values or use defaults
        self.copyToClipboard = UserDefaults.standard.object(forKey: "copyToClipboard") as? Bool ?? true
        self.saveToFile = UserDefaults.standard.object(forKey: "saveToFile") as? Bool ?? true  // Changed default to true

        // Default to temp directory (cleared on reboot) for "jetable" workflow
        self.saveFolderPath = UserDefaults.standard.string(forKey: "saveFolderPath") ?? (NSTemporaryDirectory() + "ScreenSnap/")

        self.imageFormat = UserDefaults.standard.string(forKey: "imageFormat") ?? "png"
        self.playSoundOnCapture = UserDefaults.standard.object(forKey: "playSoundOnCapture") as? Bool ?? true
        self.showDimensionsLabel = UserDefaults.standard.object(forKey: "showDimensionsLabel") as? Bool ?? true
        self.enableAnnotations = UserDefaults.standard.object(forKey: "enableAnnotations") as? Bool ?? true
        self.globalHotkeyEnabled = UserDefaults.standard.object(forKey: "globalHotkeyEnabled") as? Bool ?? true

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
