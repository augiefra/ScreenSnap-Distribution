//
//  SelectionWindow.swift
//  PastScreen
//
//  Simple selection window with delegate pattern
//

import Foundation
import AppKit

// Protocol simple pour communiquer avec le service
protocol SelectionWindowDelegate: AnyObject {
    func selectionWindow(_ window: SelectionWindow, didSelectRect rect: CGRect)
    func selectionWindowDidCancel(_ window: SelectionWindow)
}

class SelectionWindow: NSWindow {
    weak var selectionDelegate: SelectionWindowDelegate?
    private var selectionView: SelectionOverlayView!

    init() {
        // Créer une fenêtre couvrant tous les écrans
        let combinedFrame = NSScreen.screens.reduce(NSRect.zero) { $0.union($1.frame) }

        super.init(
            contentRect: combinedFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.ignoresMouseEvents = false
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        selectionView = SelectionOverlayView(frame: combinedFrame)
        selectionView.onComplete = { [weak self] rect in
            guard let self = self else { return }
            self.selectionDelegate?.selectionWindow(self, didSelectRect: rect)
        }
        selectionView.onCancel = { [weak self] in
            guard let self = self else { return }
            self.selectionDelegate?.selectionWindowDidCancel(self)
        }

        self.contentView = selectionView
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
        makeKeyAndOrderFront(nil)
        print("✅ [WINDOW] SelectionWindow activated and shown")
    }

    func hide() {
        orderOut(nil)
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
                    self?.onComplete?(rect)
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
                self?.onComplete?(rect)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onCancel?()
            }
        }
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
