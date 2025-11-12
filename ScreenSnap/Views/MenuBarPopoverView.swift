//
//  MenuBarPopoverView.swift
//  ScreenSnap
//
//  Quick access menu bar popover with Liquid Glass design
//

import SwiftUI

struct MenuBarPopoverView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ScreenSnap")
                        .font(.headline)
                    Text("Capture rapide")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.bottom, 8)

            Divider()

            // Quick Actions
            VStack(alignment: .leading, spacing: 8) {
                QuickActionButton(
                    icon: "viewfinder.rectangular",
                    title: "Capture d'écran",
                    subtitle: "Sélectionner une zone"
                ) {
                    takeScreenshot()
                }

                QuickActionButton(
                    icon: "macwindow",
                    title: "Capturer une fenêtre",
                    subtitle: "Choisir une app"
                ) {
                    captureWindow()
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    func takeScreenshot() {
        dismiss()
        NotificationCenter.default.post(name: .screenshotRequested, object: nil)
    }

    func captureWindow() {
        dismiss()
        NotificationCenter.default.post(name: .windowCaptureRequested, object: nil)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .opacity(isHovered ? 1 : 0.5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.1) : Color.clear)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.quickSpring, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let screenshotRequested = Notification.Name("screenshotRequested")
    static let windowCaptureRequested = Notification.Name("windowCaptureRequested")
}

#Preview {
    MenuBarPopoverView()
        .frame(width: 320)
}
