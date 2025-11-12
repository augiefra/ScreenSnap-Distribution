//
//  PermissionManager.swift
//  ScreenSnap
//
//  Comprehensive permission management with retry logic and diagnostics
//

import Foundation
import AppKit
import UserNotifications
import Combine

enum PermissionType: String, CaseIterable {
    case screenRecording = "Screen Recording"
    case accessibility = "Accessibility"
    case notifications = "Notifications"

    var icon: String {
        switch self {
        case .screenRecording: return "📱"
        case .accessibility: return "♿️"
        case .notifications: return "🔔"
        }
    }
}

enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted

    var description: String {
        switch self {
        case .authorized: return "✅ Authorized"
        case .denied: return "❌ Denied"
        case .notDetermined: return "⏳ Not Determined"
        case .restricted: return "🚫 Restricted"
        }
    }
}

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var screenRecordingStatus: PermissionStatus = .notDetermined
    @Published var accessibilityStatus: PermissionStatus = .notDetermined
    @Published var notificationStatus: PermissionStatus = .notDetermined

    private var retryCount: [PermissionType: Int] = [:]
    private let maxRetries = 3

    // MARK: - Permission Status Checking

    func checkAllPermissions() {
        print("🔍 [PERMISSIONS] Checking all permission statuses...")

        checkScreenRecordingPermission()
        checkAccessibilityPermission()
        checkNotificationPermission()

        logPermissionSummary()
    }

    func checkScreenRecordingPermission() {
        if #available(macOS 10.15, *) {
            let hasAccess = CGPreflightScreenCaptureAccess()
            screenRecordingStatus = hasAccess ? .authorized : .denied
            print("📱 [PERMISSIONS] Screen Recording: \(screenRecordingStatus.description)")
        }
    }

    func checkAccessibilityPermission() {
        let hasAccess = AXIsProcessTrusted()
        accessibilityStatus = hasAccess ? .authorized : .denied
        print("♿️ [PERMISSIONS] Accessibility: \(accessibilityStatus.description)")
    }

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.notificationStatus = .authorized
                case .denied:
                    self.notificationStatus = .denied
                case .notDetermined:
                    self.notificationStatus = .notDetermined
                @unknown default:
                    self.notificationStatus = .restricted
                }
                print("🔔 [PERMISSIONS] Notifications: \(self.notificationStatus.description)")
                self.logNotificationDiagnostics(settings)
            }
        }
    }

    // MARK: - Permission Requests with Retry

    func requestPermission(_ type: PermissionType, completion: @escaping (Bool) -> Void) {
        let currentRetry = retryCount[type] ?? 0

        if currentRetry >= maxRetries {
            print("⚠️ [PERMISSIONS] Max retries reached for \(type.rawValue)")
            showMaxRetriesAlert(for: type)
            completion(false)
            return
        }

        retryCount[type] = currentRetry + 1
        print("🔄 [PERMISSIONS] Requesting \(type.rawValue) (attempt \(currentRetry + 1)/\(maxRetries))...")

        switch type {
        case .screenRecording:
            requestScreenRecording(completion: completion)
        case .accessibility:
            requestAccessibility(completion: completion)
        case .notifications:
            requestNotifications(completion: completion)
        }
    }

    private func requestScreenRecording(completion: @escaping (Bool) -> Void) {
        if #available(macOS 10.15, *) {
            let wasAuthorized = CGPreflightScreenCaptureAccess()
            if !wasAuthorized {
                CGRequestScreenCaptureAccess()

                // Check again after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.checkScreenRecordingPermission()
                    completion(self.screenRecordingStatus == .authorized)
                }
            } else {
                completion(true)
            }
        }
    }

    private func requestAccessibility(completion: @escaping (Bool) -> Void) {
        let wasAuthorized = AXIsProcessTrusted()
        if !wasAuthorized {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

            // Check again after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkAccessibilityPermission()
                completion(self.accessibilityStatus == .authorized)
            }
        } else {
            completion(true)
        }
    }

    private func requestNotifications(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [PERMISSIONS] Notification auth error: \(error)")
                }
                self.checkNotificationPermission()
                completion(granted)
            }
        }
    }

    // MARK: - Diagnostics

    private func logPermissionSummary() {
        print("""

        ═══════════════════════════════════════
        📊 PERMISSION STATUS SUMMARY
        ═══════════════════════════════════════
        📱 Screen Recording: \(screenRecordingStatus.description)
        ♿️ Accessibility:     \(accessibilityStatus.description)
        🔔 Notifications:     \(notificationStatus.description)
        ═══════════════════════════════════════

        """)
    }

    private func logNotificationDiagnostics(_ settings: UNNotificationSettings) {
        let authStatus: String
        switch settings.authorizationStatus {
        case .authorized: authStatus = "Authorized"
        case .denied: authStatus = "Denied"
        case .notDetermined: authStatus = "Not Determined"
        case .provisional: authStatus = "Provisional"
        case .ephemeral: authStatus = "Ephemeral"
        @unknown default: authStatus = "Unknown"
        }

        print("""

        ═══════════════════════════════════════
        🔔 NOTIFICATION DIAGNOSTICS
        ═══════════════════════════════════════
        Authorization Status:  \(authStatus) (\(settings.authorizationStatus.rawValue))
        Alert Setting:         \(settings.alertSetting.rawValue)
        Badge Setting:         \(settings.badgeSetting.rawValue)
        Sound Setting:         \(settings.soundSetting.rawValue)
        Notification Center:   \(settings.notificationCenterSetting.rawValue)
        Lock Screen:           \(settings.lockScreenSetting.rawValue)

        🔍 ACTIVATION POLICY
        Current Policy:        \(NSApp.activationPolicy().rawValue)
        LSUIElement in Info:   \(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") != nil ? "YES" : "NO")

        💡 KNOWN ISSUE
        Apps with LSUIElement=true or .accessory policy
        are filtered by macOS from showing UNUserNotifications.
        This is a macOS design limitation, not an app bug.
        ═══════════════════════════════════════

        """)
    }

    // MARK: - User Feedback

    func allPermissionsGranted() -> Bool {
        return screenRecordingStatus == .authorized &&
               accessibilityStatus == .authorized &&
               notificationStatus == .authorized
    }

    func getMissingPermissions() -> [PermissionType] {
        var missing: [PermissionType] = []

        if screenRecordingStatus != .authorized {
            missing.append(.screenRecording)
        }
        if accessibilityStatus != .authorized {
            missing.append(.accessibility)
        }
        if notificationStatus != .authorized {
            missing.append(.notifications)
        }

        return missing
    }

    func showPermissionAlert(for permissions: [PermissionType]) {
        let alert = NSAlert()
        alert.messageText = "Permissions Required"
        alert.informativeText = """
        ScreenSnap needs the following permissions to work properly:

        \(permissions.map { "\($0.icon) \($0.rawValue)" }.joined(separator: "\n"))

        Please enable them in System Preferences > Privacy & Security.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            openSystemPreferences()
        }
    }

    private func showMaxRetriesAlert(for type: PermissionType) {
        let alert = NSAlert()
        alert.messageText = "\(type.icon) \(type.rawValue) Permission Required"
        alert.informativeText = """
        ScreenSnap has reached the maximum number of permission requests.

        Please manually enable \(type.rawValue) in:
        System Preferences > Privacy & Security > \(type.rawValue)
        """
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "OK")

        if alert.runModal() == .alertFirstButtonReturn {
            openSystemPreferences()
        }
    }

    func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Reset

    func resetRetryCounters() {
        retryCount.removeAll()
        print("🔄 [PERMISSIONS] Retry counters reset")
    }
}
