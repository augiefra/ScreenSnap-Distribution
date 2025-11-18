//
//  LaunchAtLoginManager.swift
//  PastScreen
//
//  Launch at login functionality using ServiceManagement
//

import Foundation
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private init() {}

    /// Check if launch at login is enabled
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // Fallback for older macOS versions (not applicable for macOS 14+ requirement)
            return false
        }
    }

    /// Enable or disable launch at login
    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status == .enabled {
                        NSLog("✅ [LAUNCH] Already enabled")
                    } else {
                        try SMAppService.mainApp.register()
                        NSLog("✅ [LAUNCH] Enabled successfully")
                    }
                } else {
                    if SMAppService.mainApp.status == .notRegistered {
                        NSLog("✅ [LAUNCH] Already disabled")
                    } else {
                        try SMAppService.mainApp.unregister()
                        NSLog("✅ [LAUNCH] Disabled successfully")
                    }
                }
            } catch {
                NSLog("❌ [LAUNCH] Failed to \(enabled ? "enable" : "disable"): \(error.localizedDescription)")
            }
        }
    }
}
