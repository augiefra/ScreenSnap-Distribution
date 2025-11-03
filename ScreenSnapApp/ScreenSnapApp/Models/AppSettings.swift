import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("saveFolderPath") var saveFolderPath: String = NSTemporaryDirectory() + "ScreenSnap/"
    @AppStorage("playSoundOnCapture") var playSoundOnCapture: Bool = true
    @AppStorage("hotKeyModifiers") var hotKeyModifiers: Int = 0
    @AppStorage("hotKeyKeyCode") var hotKeyKeyCode: Int = 0
    @AppStorage("copyToClipboard") var copyToClipboard: Bool = true
    @AppStorage("saveToFile") var saveToFile: Bool = true
    @AppStorage("imageFormat") var imageFormat: String = "png"
    @AppStorage("clearOnRestart") var clearOnRestart: Bool = true

    private init() {
        // Ensure the default folder exists
        ensureFolderExists()

        // Set default hotkey if not set (Cmd+Shift+5)
        if hotKeyKeyCode == 0 {
            hotKeyModifiers = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
            hotKeyKeyCode = 23 // Key code for '5'
        }

        // Clear folder on launch if setting is enabled
        if clearOnRestart {
            clearSaveFolder()
        }
    }

    func ensureFolderExists() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: saveFolderPath) {
            try? fileManager.createDirectory(atPath: saveFolderPath, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func clearSaveFolder() {
        let fileManager = FileManager.default
        guard let items = try? fileManager.contentsOfDirectory(atPath: saveFolderPath) else { return }

        for item in items {
            let itemPath = saveFolderPath + item
            try? fileManager.removeItem(atPath: itemPath)
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
}
