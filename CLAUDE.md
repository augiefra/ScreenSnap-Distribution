# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ScreenSnap is a native macOS menu bar application for taking quick screenshots and automatically copying them to the clipboard for pasting into IDEs (VSCode, Cursor, Zed, etc.). Built with SwiftUI and AppKit for macOS 13.0+.

## Build and Development Commands

### Xcode Workflow
This project requires Xcode (not Swift Package Manager alone) because SPM doesn't fully support macOS GUI applications.

```bash
# Open Xcode to create/open the project
open -a Xcode

# For first-time setup, create a new macOS App project:
# - Product Name: ScreenSnap
# - Interface: SwiftUI
# - Language: Swift
# - Import files from ScreenSnapApp/ScreenSnapApp directory
```

### Building
- **Debug build**: `⌘R` in Xcode
- **Release archive**: Product → Archive in Xcode
- **Install to /Applications**: Copy built app from DerivedData

### Running the App
The app launches as a menu bar item (camera icon) in the macOS status bar, not as a traditional windowed application.

## Architecture

### App Structure (MVVM Pattern)

**Entry Point**: `ScreenSnapAppApp.swift`
- Main `@main` app entry with SwiftUI `App` protocol
- `AppDelegate` handles menu bar lifecycle and service initialization
- Creates `NSStatusItem` for menu bar presence
- Initializes and coordinates `ScreenshotService` and `HotKeyManager`

**Models**: `Models/AppSettings.swift`
- Singleton settings manager using `@AppStorage` for persistence
- Handles preferences: save folder, hotkey configuration, image format, clipboard/file options
- Auto-initializes default hotkey (⌘⇧5) if not set
- Implements folder cleanup on restart if `clearOnRestart` enabled

**Services**:
- `ScreenshotService.swift`: Core screenshot capture logic
  - Creates `SelectionWindow` for interactive area selection
  - Uses `CGDisplayCreateImage` for screen region capture
  - Handles clipboard operations via `NSPasteboard`
  - Saves to disk with timestamp-based filenames
  - Multi-screen support with combined frame handling

- `HotKeyManager.swift`: Global keyboard shortcut registration
  - Uses Carbon API (`RegisterEventHotKey`) for system-wide hotkeys
  - Supports all modifier keys (⌘⌥⌃⇧)
  - Posts notifications to trigger screenshot capture
  - Provides utilities for key code/modifier display

**Views**: `Views/SettingsView.swift`
- SwiftUI settings interface (opened via menu bar)
- Three tabs: General, Shortcut, Storage
- Manages user preferences for capture behavior

### Key Architectural Patterns

**Menu Bar Application**:
- `LSUIElement = YES` in Info.plist hides dock icon
- Lives in `NSStatusBar.system` exclusively

**Service Coordination**:
- AppDelegate owns both services (ScreenshotService, HotKeyManager)
- Services communicate via NotificationCenter for loose coupling
- Hotkey → Notification → AppDelegate → ScreenshotService flow

**Screenshot Capture Flow**:
1. Hotkey pressed or menu item selected
2. `SelectionWindow` created covering all screens with semi-transparent overlay
3. User drags selection rectangle (`SelectionView` handles mouse events)
4. On mouse up: `performCapture()` with selected CGRect
5. Coordinate conversion (AppKit to screen coordinates)
6. `CGDisplayCreateImage()` captures region
7. Parallel operations: copy to clipboard + save to file (if enabled)
8. Notification displayed to user

**Coordinate System Handling**:
- AppKit uses bottom-left origin
- Screen capture uses top-left origin
- `captureScreenRegion()` performs coordinate flipping

## Critical Implementation Details

### Permissions Requirements
The app requires two system permissions granted via System Preferences:
- **Screen Recording**: For `CGDisplayCreateImage` access
- **Accessibility**: For global hotkey registration (Carbon API)

Add to Info.plist:
- `NSAppleEventsUsageDescription`: Required for hotkey access
- `NSScreenCaptureUsageDescription`: Required for screen capture

### Entitlements
Check `ScreenSnapApp.entitlements` for required app sandbox settings.

### Carbon API for Hotkeys
Modern Swift must bridge to Carbon's C API for global hotkeys. The `HotKeyManager` uses:
- `RegisterEventHotKey()` for registration
- `InstallEventHandler()` for event handling
- Custom `EventHotKeyID` with signature/id

### Multi-Screen Support
The `SelectionWindow` uses `NSScreen.screens` to create a combined frame covering all displays, allowing captures across monitor boundaries.

### File Naming Convention
Screenshots saved with format: `Screenshot-YYYY-MM-dd-HH-mm-ss.{png|jpg}`

### Settings Persistence
All settings use `@AppStorage` which backs to UserDefaults. Settings survive app restarts automatically.

## macOS-Specific Considerations

- **Minimum Version**: macOS 13.0 (Ventura) - set in deployment target
- **System Sounds**: Uses `NSSound(named: "Pop")` for shutter sound
- **Notifications**: Uses deprecated `NSUserNotification` (may need migration to `UNUserNotificationCenter`)
- **Pasteboard**: Uses `NSPasteboard.general` for clipboard operations
- **Bundle Identifier**: Must be unique (e.g., `com.yourcompany.screensnap`)

## Testing Notes

Since this is a GUI-centric macOS app with system permissions, testing is primarily manual:
- Test hotkey registration with different modifier combinations
- Test screen capture on single/multi-monitor setups
- Test clipboard integration with various IDEs
- Test settings persistence across app restarts
- Test folder cleanup on restart functionality

## Known Limitations

- Deprecated notification API (`NSUserNotification` vs modern `UNUserNotificationCenter`)
- No automated tests currently in project
- Requires manual Xcode project creation (SPM limitation for GUI apps)
- Sound file (`camera-shutter.mp3`) referenced but may not exist in bundle
