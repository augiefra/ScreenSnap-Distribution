//
//  LiquidGlassComponents.swift
//  ScreenSnap
//
//  Reusable Liquid Glass UI components for macOS 14+
//

import SwiftUI
import AppKit

// MARK: - Liquid Glass Background

struct LiquidGlassBackground: View {
    var material: Material = .ultraThinMaterial
    var cornerRadius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(material)
    }
}

// MARK: - Glass Button

struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? .regularMaterial : .thinMaterial)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Vibrancy Text

struct VibrancyText: View {
    let text: String
    let font: Font

    init(_ text: String, font: Font = .body) {
        self.text = text
        self.font = font
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(.primary)
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - Blur Overlay (for screenshot selection)

struct BlurOverlay: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

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

// MARK: - Dimension Label (Glass style)

struct DimensionLabel: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            Text(String(format: "%.0f", width))
            Image(systemName: "xmark")
                .font(.caption)
            Text(String(format: "%.0f", height))
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Spring Animation Helper

extension Animation {
    static var smoothSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.3)
    }

    static var quickSpring: Animation {
        .spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.2)
    }
}
