//
//  OnboardingView.swift
//  ScreenSnap
//
//  Multi-page onboarding with liquid glass design and permission requests
//

import SwiftUI
import AppKit
import ScreenCaptureKit

// MARK: - OnboardingWindow (Custom NSWindow that can become key)

class OnboardingWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - OnboardingManager

class OnboardingManager {
    static let shared = OnboardingManager()

    private var onboardingWindow: OnboardingWindow?
    private var hostingController: NSHostingController<OnboardingContentView>?
    private let hasSeenOnboardingKey = "hasSeenOnboarding"

    var hasSeenOnboarding: Bool {
        get {
            let value = UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
            NSLog("🔑 [ONBOARDING] hasSeenOnboarding getter called, returning: \(value)")
            return value
        }
        set {
            NSLog("🔑 [ONBOARDING] hasSeenOnboarding setter called with: \(newValue)")
            UserDefaults.standard.set(newValue, forKey: hasSeenOnboardingKey)
        }
    }

    func showIfNeeded() {
        NSLog("🔍 [ONBOARDING] showIfNeeded called, hasSeenOnboarding = \(hasSeenOnboarding)")
        guard !hasSeenOnboarding else {
            NSLog("ℹ️ [ONBOARDING] Already seen, skipping")
            return
        }
        NSLog("✅ [ONBOARDING] First launch detected, calling show()")
        show()
    }

    func show() {
        NSLog("📢 [ONBOARDING] show() method called!")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                NSLog("⚠️ [ONBOARDING] self is nil in show()")
                return
            }

            NSLog("✨ [ONBOARDING] Showing welcome screen")

            // Dismiss if already showing
            if self.onboardingWindow != nil {
                NSLog("🗑️ [ONBOARDING] Existing window found, dismissing first")
                self.dismiss()
                // Wait for dismissal to complete before showing new window
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.show()
                }
                return
            }

            // Create onboarding view
            NSLog("🏗️ [ONBOARDING] Creating onboarding view...")
            let onboardingView = OnboardingContentView(
                onDismiss: { [weak self] in
                    self?.hasSeenOnboarding = true
                    self?.dismiss()
                }
            )

            let hostingController = NSHostingController(rootView: onboardingView)
            self.hostingController = hostingController
            NSLog("✅ [ONBOARDING] Hosting controller created")

            // Calculate window size and position (centered)
            let windowWidth: CGFloat = 620
            let windowHeight: CGFloat = 640

            guard let screen = NSScreen.main else {
                NSLog("❌ [ONBOARDING] No main screen found")
                return
            }

            let screenFrame = screen.visibleFrame
            let windowRect = NSRect(
                x: screenFrame.midX - windowWidth / 2,
                y: screenFrame.midY - windowHeight / 2,
                width: windowWidth,
                height: windowHeight
            )
            NSLog("📐 [ONBOARDING] Window rect: \(windowRect)")

            // Create floating window with rounded corners
            NSLog("🪟 [ONBOARDING] Creating OnboardingWindow...")
            let window = OnboardingWindow(
                contentRect: windowRect,
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            NSLog("✅ [ONBOARDING] Window created")

            window.contentViewController = hostingController
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isMovableByWindowBackground = true
            NSLog("⚙️ [ONBOARDING] Window properties configured")

            // Liquid glass rounded corners
            if let contentView = window.contentView {
                contentView.wantsLayer = true
                contentView.layer?.cornerRadius = 20
                contentView.layer?.masksToBounds = true
                contentView.layer?.cornerCurve = .continuous  // Apple's smooth corners
                NSLog("🎨 [ONBOARDING] Content view styled with rounded corners")
            }

            self.onboardingWindow = window
            NSLog("💾 [ONBOARDING] Window reference stored")

            // Show with animation
            window.alphaValue = 0
            NSLog("👁️ [ONBOARDING] Calling makeKeyAndOrderFront...")
            window.makeKeyAndOrderFront(nil)
            NSLog("📢 [ONBOARDING] Calling NSApp.activate...")
            NSApp.activate(ignoringOtherApps: true)
            NSLog("🎬 [ONBOARDING] Starting fade-in animation...")

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                window.animator().alphaValue = 1.0
            }, completionHandler: {
                NSLog("✅ [ONBOARDING] Window displayed and animation complete!")
            })
        }
    }

    func dismiss() {
        NSLog("🗑️ [ONBOARDING] Dismiss called")

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = self.onboardingWindow else {
                NSLog("⚠️ [ONBOARDING] No window to dismiss")
                return
            }

            NSLog("🗑️ [ONBOARDING] Closing window...")

            // Fade out animation
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().alphaValue = 0.0
            }, completionHandler: {
                // Delayed cleanup to avoid release issues
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    window.orderOut(nil)

                    // Clear references
                    self?.hostingController = nil
                    self?.onboardingWindow = nil

                    NSLog("✅ [ONBOARDING] Window dismissed successfully")
                }
            })
        }
    }
}

// MARK: - OnboardingPage

enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case screenRecording = 1
    case accessibility = 2
    case autoCleanup = 3
    case clipboard = 4

    var title: String {
        switch self {
        case .welcome: return NSLocalizedString("onboarding.page1.title", comment: "")
        case .screenRecording: return NSLocalizedString("onboarding.permissions.screen_recording.title", comment: "")
        case .accessibility: return NSLocalizedString("onboarding.permissions.accessibility.title", comment: "")
        case .autoCleanup: return NSLocalizedString("onboarding.page2.title", comment: "")
        case .clipboard: return NSLocalizedString("onboarding.page3.title", comment: "")
        }
    }

    var description: String {
        switch self {
        case .welcome: return NSLocalizedString("onboarding.page1.description", comment: "")
        case .screenRecording: return NSLocalizedString("onboarding.permissions.screen_recording.description", comment: "")
        case .accessibility: return NSLocalizedString("onboarding.permissions.accessibility.description", comment: "")
        case .autoCleanup: return NSLocalizedString("onboarding.page2.description", comment: "")
        case .clipboard: return NSLocalizedString("onboarding.page3.description", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .welcome: return "bolt.fill"
        case .screenRecording: return "video.fill"
        case .accessibility: return "keyboard.fill"
        case .autoCleanup: return "sparkles"
        case .clipboard: return "doc.on.clipboard.fill"
        }
    }

    var color: Color {
        switch self {
        case .welcome: return .yellow
        case .screenRecording: return .red
        case .accessibility: return .blue
        case .autoCleanup: return .purple
        case .clipboard: return .cyan
        }
    }
}

// MARK: - OnboardingContentView

struct OnboardingContentView: View {
    let onDismiss: () -> Void

    @State private var currentPage: OnboardingPage = .welcome
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    @State private var screenRecordingGranted = false
    @State private var accessibilityGranted = false

    var body: some View {
        ZStack {
            // Background blur effect
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("ScreenSnap")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    Text(NSLocalizedString("onboarding.subtitle", comment: ""))
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 72)
                .padding(.bottom, 40)

                // Page content
                pageContent
                    .frame(height: 270)
                    .padding(.horizontal, 32)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(OnboardingPage.allCases, id: \.self) { page in
                        Circle()
                            .fill(currentPage == page ? currentPage.color : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 48)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage != .welcome {
                        Button(action: previousPage) {
                            Text(NSLocalizedString("onboarding.button.previous", comment: ""))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: nextPage) {
                        Text(buttonTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [currentPage.color, currentPage.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: currentPage.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 620, height: 640)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            // Don't auto-check permissions to avoid system pop-ups
            // checkPermissions()
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                Circle()
                    .fill(currentPage.color.opacity(0.2))
                    .frame(width: 90, height: 90)

                Image(systemName: currentPage.icon)
                    .font(.system(size: 44))
                    .foregroundColor(currentPage.color)
            }
            .padding(.top, 12)
            .padding(.bottom, 18)

            // Title
            Text(currentPage.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Description
            Text(currentPage.description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 30)
                .padding(.bottom, 12)

            // Permission buttons for permission pages
            if currentPage == .screenRecording {
                permissionButton(
                    title: NSLocalizedString("onboarding.permissions.grant", comment: ""),
                    granted: screenRecordingGranted,
                    action: requestScreenRecordingPermission
                )
                .padding(.top, 24)
            } else if currentPage == .accessibility {
                permissionButton(
                    title: NSLocalizedString("onboarding.permissions.grant", comment: ""),
                    granted: accessibilityGranted,
                    action: requestAccessibilityPermission
                )
                .padding(.top, 24)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .id(currentPage)
    }

    private func permissionButton(title: String, granted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if granted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                Text(granted ? NSLocalizedString("onboarding.permissions.granted", comment: "") : title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(granted ? .green : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(granted ? Color.green.opacity(0.2) : currentPage.color)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(granted)
    }

    private var buttonTitle: String {
        if currentPage == .clipboard {
            return NSLocalizedString("onboarding.button.start", comment: "")
        } else {
            return NSLocalizedString("onboarding.button.next", comment: "")
        }
    }

    private func nextPage() {
        if currentPage == .clipboard {
            onDismiss()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if let nextIndex = OnboardingPage(rawValue: currentPage.rawValue + 1) {
                    currentPage = nextIndex
                }
            }
        }
    }

    private func previousPage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let prevIndex = OnboardingPage(rawValue: currentPage.rawValue - 1) {
                currentPage = prevIndex
            }
        }
    }

    private func checkPermissions() {
        // Silently check accessibility permission (doesn't trigger pop-up)
        accessibilityGranted = AXIsProcessTrusted()

        // Silently check screen recording permission
        if #available(macOS 14.0, *) {
            // For macOS 14+, we can't check without triggering permission request
            // So we don't check automatically
            screenRecordingGranted = false
        } else {
            screenRecordingGranted = CGPreflightScreenCaptureAccess()
        }
    }

    private func requestScreenRecordingPermission() {
        // Always open System Preferences directly
        openSystemPreferences(pane: "ScreenCapture")

        // Start polling to check if permission was granted
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if #available(macOS 14.0, *) {
                Task { @MainActor in
                    do {
                        let content = try await SCShareableContent.current
                        if !content.displays.isEmpty {
                            self.screenRecordingGranted = true
                            timer.invalidate()
                            print("✅ Screen Recording permission granted")
                        }
                    } catch {
                        // Still waiting for permission
                    }
                }
            } else {
                if CGPreflightScreenCaptureAccess() {
                    self.screenRecordingGranted = true
                    timer.invalidate()
                    print("✅ Screen Recording permission granted")
                }
            }
        }
    }

    private func requestAccessibilityPermission() {
        // Open System Preferences directly for Accessibility
        openSystemPreferences(pane: "Accessibility")

        // Start polling to check if permission was granted
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if AXIsProcessTrusted() {
                self.accessibilityGranted = true
                timer.invalidate()
                print("✅ Accessibility permission granted")
            }
        }
    }

    private func openSystemPreferences(pane: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - VisualEffectView (NSVisualEffectView wrapper)

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview

struct OnboardingContentView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContentView(onDismiss: {})
            .frame(width: 620, height: 560)
    }
}
