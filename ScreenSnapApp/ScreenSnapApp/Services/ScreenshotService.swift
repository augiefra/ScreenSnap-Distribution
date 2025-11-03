import Foundation
import AppKit
import CoreGraphics
import AVFoundation

class ScreenshotService: NSObject {
    private var selectionWindow: SelectionWindow?
    private var soundPlayer: AVAudioPlayer?

    override init() {
        super.init()
        prepareSoundPlayer()
    }

    func captureScreenshot() {
        // Hide any existing selection window
        selectionWindow?.close()

        // Create and show selection window
        selectionWindow = SelectionWindow { [weak self] selectedRect in
            self?.performCapture(rect: selectedRect)
        }
        selectionWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func performCapture(rect: CGRect) {
        guard let cgImage = captureScreenRegion(rect: rect) else {
            print("Failed to capture screen region")
            return
        }

        let nsImage = NSImage(cgImage: cgImage, size: rect.size)

        // Play sound if enabled
        if AppSettings.shared.playSoundOnCapture {
            playShutterSound()
        }

        // Copy to clipboard if enabled
        if AppSettings.shared.copyToClipboard {
            copyToClipboard(image: nsImage)
        }

        // Save to file if enabled
        if AppSettings.shared.saveToFile {
            saveToFile(image: nsImage)
        }

        // Show notification
        showNotification()
    }

    private func captureScreenRegion(rect: CGRect) -> CGImage? {
        // Convert from AppKit coordinates to screen coordinates
        guard let screenFrame = NSScreen.main?.frame else { return nil }
        let flippedRect = CGRect(
            x: rect.origin.x,
            y: screenFrame.height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        let displayID = CGMainDisplayID()
        return CGDisplayCreateImage(displayID, rect: flippedRect)
    }

    private func copyToClipboard(image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    private func saveToFile(image: NSImage) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return
        }

        let fileType: NSBitmapImageRep.FileType
        let fileExtension: String

        switch AppSettings.shared.imageFormat {
        case "jpg", "jpeg":
            fileType = .jpeg
            fileExtension = "jpg"
        case "png":
            fileType = .png
            fileExtension = "png"
        default:
            fileType = .png
            fileExtension = "png"
        }

        guard let data = bitmapImage.representation(using: fileType, properties: [:]) else {
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "Screenshot-\(timestamp).\(fileExtension)"

        AppSettings.shared.ensureFolderExists()
        let filePath = AppSettings.shared.saveFolderPath + filename

        try? data.write(to: URL(fileURLWithPath: filePath))
    }

    private func prepareSoundPlayer() {
        // Use system screenshot sound
        if let soundURL = Bundle.main.url(forResource: "camera-shutter", withExtension: "mp3") {
            try? soundPlayer = AVAudioPlayer(contentsOf: soundURL)
            soundPlayer?.prepareToPlay()
        }
    }

    private func playShutterSound() {
        // Play system sound (alternative if custom sound not available)
        NSSound(named: "Pop")?.play()
    }

    private func showNotification() {
        let notification = NSUserNotification()
        notification.title = "ScreenSnap"
        notification.informativeText = "Capture d'écran enregistrée"
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Selection Window
class SelectionWindow: NSWindow {
    private var selectionView: SelectionView?
    private var onSelection: ((CGRect) -> Void)?

    init(onSelection: @escaping (CGRect) -> Void) {
        self.onSelection = onSelection

        // Create window covering all screens
        let mainScreen = NSScreen.main ?? NSScreen.screens[0]
        var combinedFrame = mainScreen.frame

        for screen in NSScreen.screens {
            combinedFrame = combinedFrame.union(screen.frame)
        }

        super.init(
            contentRect: combinedFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.level = .screenSaver
        self.ignoresMouseEvents = false
        self.hasShadow = false

        selectionView = SelectionView(frame: combinedFrame) { [weak self] rect in
            self?.close()
            onSelection(rect)
        }

        if let selectionView = selectionView {
            self.contentView = selectionView
        }
    }
}

// MARK: - Selection View
class SelectionView: NSView {
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var onSelection: ((CGRect) -> Void)?

    init(frame: NSRect, onSelection: @escaping (CGRect) -> Void) {
        self.onSelection = onSelection
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = event.locationInWindow
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = event.locationInWindow
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint, let end = currentPoint else { return }

        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        if rect.width > 10 && rect.height > 10 {
            onSelection?(rect)
        } else {
            window?.close()
        }
    }

    override func keyDown(with event: NSEvent) {
        // Cancel selection on ESC
        if event.keyCode == 53 { // ESC key
            window?.close()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let start = startPoint, let end = currentPoint else { return }

        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        // Draw selection rectangle
        NSColor.white.withAlphaComponent(0.3).setFill()
        rect.fill()

        NSColor.white.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 2
        path.stroke()

        // Draw dimensions label
        let dimensions = String(format: "%.0f × %.0f", rect.width, rect.height)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        let labelSize = dimensions.size(withAttributes: attributes)
        let labelRect = CGRect(
            x: rect.maxX - labelSize.width - 5,
            y: rect.maxY + 5,
            width: labelSize.width + 4,
            height: labelSize.height + 4
        )

        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: labelRect, xRadius: 3, yRadius: 3).fill()

        dimensions.draw(at: CGPoint(x: labelRect.minX + 2, y: labelRect.minY + 2), withAttributes: attributes)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}
