//
//  CustomNotificationView.swift
//  ScreenSnap
//
//  Custom notification system that works with .accessory mode apps
//  Alternative to UNUserNotification which doesn't work for menu bar only apps
//

import SwiftUI
import AppKit

// MARK: - CustomNotificationManager

class CustomNotificationManager {
    static let shared = CustomNotificationManager()

    private var notificationPanel: NSPanel?
    private var dismissTimer: Timer?
    private let notificationDuration: TimeInterval = 4.0

    func show(title: String, message: String, filePath: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            print("📢 [CUSTOM NOTIF] Showing: \(title) - \(message)")

            // Dismiss any existing notification
            self.dismiss()

            // Create notification content
            let notificationView = CustomNotificationContentView(
                title: title,
                message: message,
                filePath: filePath,
                onDismiss: { [weak self] in
                    self?.dismiss()
                }
            )

            // Create hosting controller
            let hostingController = NSHostingController(rootView: notificationView)

            // Calculate notification position (top-right corner)
            let notificationWidth: CGFloat = 360
            let notificationHeight: CGFloat = 100
            let screenPadding: CGFloat = 20

            guard let screen = NSScreen.main else {
                print("❌ [CUSTOM NOTIF] No main screen found")
                return
            }

            let screenFrame = screen.visibleFrame
            let notificationRect = NSRect(
                x: screenFrame.maxX - notificationWidth - screenPadding,
                y: screenFrame.maxY - notificationHeight - screenPadding,
                width: notificationWidth,
                height: notificationHeight
            )

            // Create panel
            let panel = NSPanel(
                contentRect: notificationRect,
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )

            panel.contentViewController = hostingController
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false

            self.notificationPanel = panel

            // Show with animation
            panel.alphaValue = 0
            panel.orderFrontRegardless()

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                panel.animator().alphaValue = 1.0
            }, completionHandler: {
                print("✅ [CUSTOM NOTIF] Notification displayed")
            })

            // Auto-dismiss after duration
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: self.notificationDuration, repeats: false) { [weak self] _ in
                print("⏱️ [CUSTOM NOTIF] Auto-dismiss")
                self?.dismiss()
            }
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        guard let panel = notificationPanel else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            panel.animator().alphaValue = 0.0
        }, completionHandler: {
            panel.close()
            self.notificationPanel = nil
            print("🗑️ [CUSTOM NOTIF] Notification dismissed")
        })
    }
}

// MARK: - CustomNotificationContentView

struct CustomNotificationContentView: View {
    let title: String
    let message: String
    let filePath: String?
    let onDismiss: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                if filePath != nil {
                    Button(action: {
                        openInFinder()
                    }) {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Reveal in Finder")
                }

                Button(action: {
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Dismiss")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if filePath != nil {
                openInFinder()
            }
        }
    }

    private func openInFinder() {
        guard let path = filePath else { return }
        print("🖱️ [CUSTOM NOTIF] Opening Finder: \(path)")
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        onDismiss()
    }
}

// MARK: - Preview

struct CustomNotificationContentView_Previews: PreviewProvider {
    static var previews: some View {
        CustomNotificationContentView(
            title: "📸 Screenshot Ready",
            message: "Click to reveal in Finder",
            filePath: "/tmp/test.png",
            onDismiss: {}
        )
        .frame(width: 360, height: 100)
        .previewLayout(.sizeThatFits)
    }
}
