//
//  DynamicIslandView.swift
//  PastScreen
//
//  Lightweight menu bar confirmation pill
//

import AppKit

/// Manager for temporary "✓ Saved" indicator in the menu bar
class DynamicIslandManager {
    static let shared = DynamicIslandManager()
    private var pillStatusItem: NSStatusItem?
    private var dismissTimer: Timer?

    func show(message: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.dismiss()

            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            guard let button = statusItem.button else { return }

            pillStatusItem = statusItem
            button.title = "✓ \(message)"
            button.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
            button.contentTintColor = .systemGreen
            button.isBordered = true
            button.bezelStyle = .rounded
            button.focusRingType = .none
            button.alphaValue = 0

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                button.animator().alphaValue = 1
            }

            dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.dismiss()
            }
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        if let item = pillStatusItem, let button = item.button {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                button.animator().alphaValue = 0
            }, completionHandler: {
                NSStatusBar.system.removeStatusItem(item)
            })
        }
        pillStatusItem = nil
    }
}
