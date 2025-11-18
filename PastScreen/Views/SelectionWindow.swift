//
//  SelectionWindow.swift
//  PastScreen
//
//  Multi-screen selection window manager
//

import Foundation
import AppKit

// Protocol simple pour communiquer avec le service
protocol SelectionWindowDelegate: AnyObject {
    func selectionWindow(_ window: SelectionWindow, didSelectRect rect: CGRect)
    func selectionWindowDidCancel(_ window: SelectionWindow)
}

// MARK: - Overlay Window for Multi-Screen Support

class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        // Allow ESC to propagate to parent SelectionWindow
        if event.keyCode == 53 { // ESC
            // Will be handled by SelectionOverlayView
            super.keyDown(with: event)
        } else {
            super.keyDown(with: event)
        }
    }
}

class SelectionWindow: NSWindow {
    weak var selectionDelegate: SelectionWindowDelegate?

    // Multi-screen support: one window per screen
    private var overlayWindows: [NSWindow] = []
    private var sharedOverlayView: SelectionOverlayView!

    init() {
        // Create main window (first screen) for NSWindow inheritance
        let mainScreen = NSScreen.main ?? NSScreen.screens.first!

        super.init(
            contentRect: mainScreen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        setupMultiScreenOverlays()
    }

    private func setupMultiScreenOverlays() {
        // Calculate combined frame for shared overlay view
        let combinedFrame = NSScreen.screens.reduce(NSRect.zero) { $0.union($1.frame) }

        // Create shared overlay view that spans all screens
        sharedOverlayView = SelectionOverlayView(frame: combinedFrame)
        sharedOverlayView.onComplete = { [weak self] rect in
            guard let self = self else { return }
            self.selectionDelegate?.selectionWindow(self, didSelectRect: rect)
        }
        sharedOverlayView.onCancel = { [weak self] in
            guard let self = self else { return }
            self.selectionDelegate?.selectionWindowDidCancel(self)
        }

        // Create one window per screen
        for screen in NSScreen.screens {
            // Create window WITHOUT screen parameter to avoid auto-repositioning
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )

            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver
            window.ignoresMouseEvents = false
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            // Manually position window to this screen's frame
            window.setFrame(screen.frame, display: false)

            // Create overlay view for this screen - frame must be relative to window (0,0 origin)
            let overlayFrame = NSRect(x: 0, y: 0, width: screen.frame.width, height: screen.frame.height)
            let overlayView = SelectionOverlayView(frame: overlayFrame)
            overlayView.onComplete = { [weak self] rect in
                guard let self = self else { return }
                self.selectionDelegate?.selectionWindow(self, didSelectRect: rect)
            }
            overlayView.onCancel = { [weak self] in
                guard let self = self else { return }
                self.selectionDelegate?.selectionWindowDidCancel(self)
            }

            window.contentView = overlayView
            overlayWindows.append(window)

            print("✅ [MULTI-SCREEN] Created overlay for screen: \(screen.localizedName)")
            print("   Frame: \(screen.frame), canBecomeKey: \(window.canBecomeKey)")
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            selectionDelegate?.selectionWindowDidCancel(self)
        } else {
            super.keyDown(with: event)
        }
    }

    // Convenience methods for showing/hiding
    func show() {
        // S'assurer que PastScreen devient app active pour capter le premier clic
        NSApp.activate(ignoringOtherApps: true)

        // Show all overlay windows - use orderFrontRegardless to force display
        for (index, window) in overlayWindows.enumerated() {
            // First window becomes key, others just order front
            if index == 0 {
                window.makeKeyAndOrderFront(nil)
                print("✅ [MULTI-SCREEN] Screen \(index) (main) - Making key and ordering front")
            } else {
                window.orderFrontRegardless()
                print("✅ [MULTI-SCREEN] Screen \(index) - Ordering front regardless")
            }
            print("   Frame: \(window.frame), Level: \(window.level.rawValue)")
        }

        print("✅ [MULTI-SCREEN] Showing \(overlayWindows.count) overlay window(s)")
    }

    func hide() {
        // Hide all overlay windows immediately
        for (index, window) in overlayWindows.enumerated() {
            window.orderOut(nil)
            window.ignoresMouseEvents = true
            print("🙈 [MULTI-SCREEN] Screen \(index) - orderOut() called, ignoresMouseEvents: true")
        }
        print("✅ [MULTI-SCREEN] Hidden \(overlayWindows.count) overlay window(s)")
    }

    // Get overlay window IDs for ScreenCaptureKit exclusion
    func getOverlayWindowIDs() -> [CGWindowID] {
        let windowIDs = overlayWindows.compactMap { window -> CGWindowID? in
            let windowNumber = window.windowNumber
            guard windowNumber > 0 else { return nil }
            return CGWindowID(windowNumber)
        }
        print("🔢 [MULTI-SCREEN] Extracted \(windowIDs.count) overlay window IDs: \(windowIDs)")
        return windowIDs
    }
}

// Vue simple pour dessiner la sélection
class SelectionOverlayView: NSView {
    var onComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var endPoint: NSPoint?
    private var isDragging = false

    // Global event monitors for capturing clicks even when app is not active
    private var mouseDownMonitor: Any?
    private var mouseDraggedMonitor: Any?
    private var mouseUpMonitor: Any?

    override init(frame: NSRect) {
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupGlobalEventMonitors() {
        // Monitor pour mouseDown global (fonctionne même si l'app n'est pas active)
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self, let window = self.window, window.isVisible else { return }
            let locationInWindow = window.convertPoint(fromScreen: NSPoint(x: event.locationInWindow.x, y: NSScreen.main!.frame.height - event.locationInWindow.y))
            let locationInView = self.convert(locationInWindow, from: nil)

            if self.bounds.contains(locationInView) {
                self.startPoint = locationInView
                self.endPoint = locationInView
                self.isDragging = true
                self.needsDisplay = true
                print("✅ [GLOBAL] MouseDown captured at \(locationInView)")
            }
        }

        // Monitor pour mouseDragged global
        mouseDraggedMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            guard let self = self, self.isDragging else { return }
            let locationInWindow = self.window!.convertPoint(fromScreen: NSPoint(x: event.locationInWindow.x, y: NSScreen.main!.frame.height - event.locationInWindow.y))
            let locationInView = self.convert(locationInWindow, from: nil)

            self.endPoint = locationInView
            self.needsDisplay = true
        }

        // Monitor pour mouseUp global
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            guard let self = self, self.isDragging else { return }
            guard let start = self.startPoint, let end = self.endPoint else {
                DispatchQueue.main.async { [weak self] in
                    self?.onCancel?()
                }
                return
            }

            self.isDragging = false

            let rect = CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )

            if rect.width > 10 && rect.height > 10 {
                print("✅ [GLOBAL] MouseUp - Valid selection: \(rect)")
                DispatchQueue.main.async { [weak self] in
                    self?.emitSelection(rect: rect)
                }
            } else {
                print("❌ [GLOBAL] MouseUp - Selection too small, canceling")
                DispatchQueue.main.async { [weak self] in
                    self?.onCancel?()
                }
            }
        }
    }

    deinit {
        // Cleanup global monitors
        if let monitor = mouseDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseDraggedMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // CRITICAL: Accept first mouse click even when app is not active
    // Without this, users need to click twice when Finder/Desktop is frontmost
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    // CRITICAL: Don't delay window ordering when clicking
    // This ensures immediate event processing even when app was not frontmost
    override func shouldDelayWindowOrdering(for event: NSEvent) -> Bool {
        return false
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        endPoint = startPoint
        isDragging = true
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        endPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isDragging, let start = startPoint, let end = endPoint else {
            // Defer callback to avoid crash during event handling
            DispatchQueue.main.async { [weak self] in
                self?.onCancel?()
            }
            return
        }

        isDragging = false

        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        // Defer callbacks to avoid crash when window is hidden/deallocated during event handling
        if rect.width > 10 && rect.height > 10 {
            DispatchQueue.main.async { [weak self] in
                self?.emitSelection(rect: rect)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onCancel?()
            }
        }
    }

    /// Convert local selection rect to global screen coordinates before sending
    private func emitSelection(rect: CGRect) {
        guard let window = self.window else {
            onCancel?()
            return
        }

        // Convert from view coordinates → window → screen to get the actual desktop rect
        let rectInWindow = convert(rect, to: nil)
        let rectOnScreen = window.convertToScreen(rectInWindow)
        print("🌐 [GLOBAL] windowOrigin: \(window.frame.origin), rectInWindow: \(rectInWindow), rectOnScreen: \(rectOnScreen)")
        onComplete?(rectOnScreen)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Fond semi-transparent plus marqué
        NSColor.black.withAlphaComponent(0.2).setFill()
        bounds.fill()

        guard let start = startPoint, let end = endPoint else { return }

        let rect = NSRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        // Zone claire
        NSColor.clear.setFill()
        rect.fill(using: .copy)

        // Bordure
        NSColor.systemBlue.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 2
        path.stroke()
    }

    override var acceptsFirstResponder: Bool { true }
}
