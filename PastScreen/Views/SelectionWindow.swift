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

        // Créer la vue de sélection
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
        makeKeyAndOrderFront(nil)
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

    override init(frame: NSRect) {
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
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

        // Fond semi-transparent
        NSColor.black.withAlphaComponent(0.3).setFill()
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
