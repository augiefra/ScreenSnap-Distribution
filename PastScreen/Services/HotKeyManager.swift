//
//  HotKeyManager.swift
//  PastScreen
//
//  Created by Eric COLOGNI on 2025-11-20.
//
//  Manages the global hotkey for capturing screenshots.
//

import Foundation
import AppKit
import Combine

class HotKeyManager {

    static let shared = HotKeyManager()

    private var globalEventMonitor: Any?
    private let settings = AppSettings.shared
    private var settingsObserver: AnyCancellable?

    private init() {
        // Observe changes to the hotkey enabled setting.
        // This allows enabling/disabling the hotkey from the Settings window
        // without needing to restart the app.
        settingsObserver = settings.$globalHotkeyEnabled.sink { [weak self] enabled in
            DispatchQueue.main.async {
                if enabled {
                    self?.startMonitoring()
                } else {
                    self?.stopMonitoring()
                }
            }
        }
    }

    deinit {
        stopMonitoring()
        settingsObserver?.cancel()
    }

    /// Starts listening for the global hotkey if it's enabled in settings.
    func startMonitoring() {
        // Ensure we don't create multiple monitors by stopping any existing ones.
        stopMonitoring()

        guard settings.globalHotkeyEnabled else {
            print("ℹ️ [HOTKEY] Global hotkey is disabled in settings.")
            return
        }

        // The hotkey requires Accessibility permissions. We check for them here but
        // do not prompt the user. The onboarding flow is responsible for requesting permissions.
        guard AXIsProcessTrusted() else {
            print("⚠️ [HOTKEY] Accessibility permissions not granted. Global hotkey will not work.")
            return
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // Define the hotkey combination (Option + Command + S).
            // This logic will be updated later to support customizable hotkeys.
            let hasOption = event.modifierFlags.contains(.option)
            let hasCommand = event.modifierFlags.contains(.command)
            let hasShift = event.modifierFlags.contains(.shift)
            let hasControl = event.modifierFlags.contains(.control)

            // The desired combination is Option + Command, without Shift or Control.
            let isCorrectModifiers = hasOption && hasCommand && !hasShift && !hasControl

            // The 'S' key has a keycode of 1 on QWERTY layouts. We also check the character
            // for compatibility with other layouts.
            let isSKey = event.keyCode == 1 || event.characters?.lowercased() == "s"

            if isCorrectModifiers && isSKey {
                print("🎯 [HOTKEY] Global hotkey ⌥⌘S detected!")
                // Post a notification to decouple the hotkey detection from the action.
                // The AppDelegate will listen for this notification to trigger a screenshot.
                NotificationCenter.default.post(name: .hotKeyPressed, object: nil)
            }
        }

        if globalEventMonitor != nil {
            print("✅ [HOTKEY] Global hotkey monitor started successfully.")
        } else {
            print("❌ [HOTKEY] Failed to start global hotkey monitor.")
        }
    }

    /// Stops listening for the global hotkey.
    func stopMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
            print("⏹️ [HOTKEY] Global hotkey monitor stopped.")
        }
    }
}
