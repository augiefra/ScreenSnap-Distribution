//
//  DynamicIslandView.swift
//  ScreenSnap
//
//  Menu bar pill notification (NSStatusItem + NSPopover approach)
//

import SwiftUI
import AppKit

/// Manager for temporary menu bar pill notification
class DynamicIslandManager {
    static let shared = DynamicIslandManager()
    private var pillStatusItem: NSStatusItem?
    private var pillPopover: NSPopover?
    private var dismissTimer: Timer?

    func show(message: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            print("🟣 [PILL] Affichage de la pilule: \(message)")

            // Dismiss any existing pill
            self.dismiss()

            // Create temporary status item (pill in menu bar)
            self.pillStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

            guard let button = self.pillStatusItem?.button else {
                print("❌ [PILL] Impossible de créer le bouton")
                return
            }

            // Configure button appearance (compact capsule style)
            button.title = "✓ \(message)"

            // Style the button to look like a pill
            button.font = NSFont.systemFont(ofSize: 12, weight: .medium)

            // Create and configure popover for visual effect
            let popover = NSPopover()
            popover.contentSize = NSSize(width: 120, height: 40)
            popover.behavior = .transient
            popover.animates = true

            let pillView = PillPopoverView(message: message)
            popover.contentViewController = NSHostingController(rootView: pillView)

            self.pillPopover = popover

            // Show popover below the status item
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            print("✅ [PILL] Pilule affichée")

            // Auto-dismiss after duration
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                print("⏱️ [PILL] Auto-dismiss après \(duration)s")
                self?.dismiss()
            }
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        // Close popover
        pillPopover?.close()
        pillPopover = nil

        // Remove status item
        if let item = pillStatusItem {
            print("🗑️ [PILL] Suppression de la pilule")
            NSStatusBar.system.removeStatusItem(item)
            pillStatusItem = nil
        }
    }
}

/// SwiftUI view for the pill popover content
struct PillPopoverView: View {
    let message: String
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
