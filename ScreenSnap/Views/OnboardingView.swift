//
//  OnboardingView.swift
//  ScreenSnap
//
//  Onboarding popup with liquid glass design
//

import SwiftUI
import AppKit

// MARK: - OnboardingManager

class OnboardingManager {
    static let shared = OnboardingManager()

    private var onboardingWindow: NSWindow?
    private var hostingController: NSHostingController<OnboardingContentView>?
    private let hasSeenOnboardingKey = "hasSeenOnboarding"

    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenOnboardingKey) }
    }

    func showIfNeeded() {
        guard !hasSeenOnboarding else {
            print("ℹ️ [ONBOARDING] Already seen, skipping")
            return
        }
        show()
    }

    func show() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            print("✨ [ONBOARDING] Showing welcome screen")

            // Dismiss if already showing
            self.dismiss()

            // Create onboarding view
            let onboardingView = OnboardingContentView(
                onDismiss: { [weak self] dontShowAgain in
                    if dontShowAgain {
                        self?.hasSeenOnboarding = true
                        print("✅ [ONBOARDING] User chose 'Don't show again'")
                    }
                    self?.dismiss()
                }
            )

            let hostingController = NSHostingController(rootView: onboardingView)
            self.hostingController = hostingController

            // Calculate window size and position (centered)
            let windowWidth: CGFloat = 620
            let windowHeight: CGFloat = 560

            guard let screen = NSScreen.main else {
                print("❌ [ONBOARDING] No main screen found")
                return
            }

            let screenFrame = screen.visibleFrame
            let windowRect = NSRect(
                x: screenFrame.midX - windowWidth / 2,
                y: screenFrame.midY - windowHeight / 2,
                width: windowWidth,
                height: windowHeight
            )

            // Create floating window
            let window = NSWindow(
                contentRect: windowRect,
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            window.contentViewController = hostingController
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isMovableByWindowBackground = true

            self.onboardingWindow = window

            // Show with animation
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                window.animator().alphaValue = 1.0
            }, completionHandler: {
                print("✅ [ONBOARDING] Window displayed")
            })
        }
    }

    func dismiss() {
        print("🗑️ [ONBOARDING] Dismiss called")

        guard let window = onboardingWindow else {
            print("⚠️ [ONBOARDING] No window to dismiss")
            return
        }

        print("🗑️ [ONBOARDING] Closing window...")

        // Clean up in the right order
        window.contentViewController = nil
        window.orderOut(nil)
        window.close()

        hostingController = nil
        onboardingWindow = nil

        print("✅ [ONBOARDING] Window dismissed successfully")
    }
}

// MARK: - OnboardingContentView

struct OnboardingContentView: View {
    let onDismiss: (Bool) -> Void

    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    @State private var dontShowAgain = false

    var body: some View {
        ZStack {
            // Background blur effect
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Bienvenue dans ScreenSnap!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.top, 40)

                // Instructions
                VStack(alignment: .leading, spacing: 20) {
                    OnboardingFeatureRow(
                        icon: "command",
                        title: "Raccourci principal",
                        description: "Appuyez sur ⌥⌘S pour capturer une zone"
                    )

                    OnboardingFeatureRow(
                        icon: "doc.on.clipboard",
                        title: "Copie automatique",
                        description: "Le chemin du fichier est copié au clipboard"
                    )

                    OnboardingFeatureRow(
                        icon: "folder",
                        title: "Stockage temporaire",
                        description: "Les captures sont dans /tmp (parfait pour Zed)"
                    )

                    OnboardingFeatureRow(
                        icon: "gearshape",
                        title: "Accès aux options",
                        description: "Cliquez sur l'icône menu bar pour les réglages"
                    )
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 12)

                Spacer()

                // Bottom buttons
                VStack(spacing: 16) {
                    Toggle(isOn: $dontShowAgain) {
                        Text("Ne plus afficher")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.checkbox)

                    Button(action: {
                        onDismiss(dontShowAgain)
                    }) {
                        Text("Compris!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 620, height: 560)
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
        }
    }
}

// MARK: - OnboardingFeatureRow

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
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
        OnboardingContentView(onDismiss: { _ in })
            .frame(width: 480, height: 380)
    }
}
