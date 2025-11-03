import Foundation
import AppKit
import Carbon

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    func registerHotKey() {
        unregisterHotKey()

        let settings = AppSettings.shared
        let modifiers = UInt32(settings.hotKeyModifiers)
        let keyCode = UInt32(settings.hotKeyKeyCode)

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(("SSAP" as NSString).fourCharCode)
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        // Install event handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, inEvent, _) -> OSStatus in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .screenshotHotKeyPressed, object: nil)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        // Register hot key
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        // Listen for screenshot notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotKey),
            name: .screenshotHotKeyPressed,
            object: nil
        )
    }

    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleHotKey() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.screenshotService?.captureScreenshot()
        }
    }

    deinit {
        unregisterHotKey()
    }
}

extension Notification.Name {
    static let screenshotHotKeyPressed = Notification.Name("screenshotHotKeyPressed")
}

// MARK: - Key Code Utilities
extension HotKeyManager {
    static func keyCodeToString(_ keyCode: Int) -> String {
        let keyCodeMap: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
            51: "Delete", 53: "Escape",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        return keyCodeMap[keyCode] ?? "Unknown"
    }

    static func modifiersToString(_ modifiers: Int) -> String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))

        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }

        return parts.joined()
    }
}
