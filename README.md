# 📸 ScreenSnap

**Ultra-fast screenshots for developers**

macOS app with optimized workflow: Capture → ⌘V → Paste into your IDE!

[![Version](https://img.shields.io/badge/version-1.3-blue.svg)](https://github.com/augiefra/ScreenSnap/releases/tag/v1.3)
[![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-lightgrey.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## ✨ What's New in v1.3

- 🎨 **Redesigned Onboarding** : Improved layout with better spacing and visual hierarchy
  - Larger window (620x640) for comfortable viewing
  - Optimized spacing between elements
  - Better permission request flow
- 🐛 **Bug Fixes** : Fixed onboarding display issues and crash on close
- ✨ **Polish** : Enhanced overall user experience

## 🚀 Features

- 🧠 **Smart Clipboard** : Auto-detects your app (browsers get images, editors get paths)
- 📸 **Area Capture** : Interactive selection with translucent overlay
- 🖥️ **Full Screen Capture** : One click to capture everything
- ⚡ **Ultra-fast** : ⌥⌘S → Capture → ⌘V → Pasted!
- 📋 **Auto-copy** : Direct to clipboard for your IDEs
- 🧹 **Auto-cleanup** : Temp files cleared on reboot
- 🔔 **Notifications** : Click to open in Finder
- 🎨 **Modern Interface** : Liquid glass onboarding Apple-style
- 🌍 **Multilingual** : French, English, Spanish, German, Italian
- ⚙️ **Customizable** : Format, sound, shortcuts, storage, Dock

## 💾 Installation

### From DMG (Recommended)

1. **Download** : [ScreenSnap-1.1.dmg](https://github.com/augiefra/ScreenSnap/releases/latest)
2. **Mount** the DMG
3. **Drag** `ScreenSnap.app` to `Applications`
4. **Launch** from Applications
5. **Grant** permissions (Screen Recording + Accessibility)

### From Source

```bash
git clone https://github.com/augiefra/ScreenSnap
cd ScreenSnap
open ScreenSnap.xcodeproj
```

Then: `Product → Archive → Export`

## 🎯 Usage

### Keyboard Shortcuts

- **⌥⌘S** : Capture area (default shortcut)
- **Click menu bar icon** : Open full menu

### Menu Bar

- 📸 Capture Area ⌥⌘S
- 🖥️ Capture Full Screen
- 📁 Show Last Screenshot
- ⚙️ Preferences...
- ❌ Quit ScreenSnap

### Developer Workflow

```
1. ⌥⌘S (or click menu bar)
2. Select the area to capture
3. ⌘V in Cursor/VSCode/Zed
   → Image pasted directly!
```

**Perfect for:**
- Pasting screenshots into Claude Code, Cursor, Zed, VSCode (as Markdown paths)
- Sharing bugs on Slack, Discord, Linear, GitHub Issues (as images)
- Documenting in Figma, Notion, Obsidian (as images)

### 🧠 Smart Clipboard Detection

ScreenSnap automatically detects which app you're using and adapts the clipboard format:

**Code Editors** → File Path (for Markdown linking)
- VSCode, VSCode Insiders
- Zed
- Cursor
- Sublime Text
- Xcode
- IntelliJ, PyCharm
- Obsidian, Typora, MacDown

**Web Browsers** → Image Data (for direct paste)
- Safari, Safari Technology Preview
- Chrome, Chrome Canary
- Firefox, Firefox Developer Edition
- Edge, Edge Dev
- Brave, Brave Dev
- Arc, DIA
- Vivaldi, Chromium, Orion

**Design & Communication** → Image Data
- Figma, Sketch, Photoshop, Framer
- Slack, Discord, Linear, Notion

**Unknown Apps** → Both formats for maximum compatibility

## ⚙️ Configuration

### General Tab
- ✅ Show icon in Dock
- ✅ Copy to clipboard (auto)
- 🔊 Play sound on capture
- 📋 Show startup tutorial

### Capture Tab
- 🖼️ **Format** : PNG (lossless) or JPEG (compressed)
- ⌨️ **Shortcut** : Customizable (default ⌥⌘S)
- 🎹 Enable global shortcut

### Storage Tab
- 💾 **Save to disk** : Optional
- 📁 **Folder** : Temp (auto-cleaned) or permanent
- 🗑️ **Clear folder** : Manual cleanup

## 🌍 Supported Languages

ScreenSnap automatically detects system language:

- 🇫🇷 **Français** - Full interface + onboarding
- 🇬🇧 **English** - Full interface + onboarding
- 🇪🇸 **Español** - Full interface + onboarding
- 🇩🇪 **Deutsch** - Full interface + onboarding
- 🇮🇹 **Italiano** - Full interface + onboarding

## 🛠️ Development

### Prerequisites
- macOS 13.0+ (Ventura)
- Xcode 15+
- Swift 5.9+

### Project Structure

```
ScreenSnap/
├── ScreenSnap/
│   ├── ScreenSnapApp.swift           # AppKit entry point
│   ├── Models/
│   │   └── AppSettings.swift         # Singleton settings
│   ├── Views/
│   │   ├── SettingsView.swift        # SwiftUI preferences
│   │   ├── ModernOnboardingView.swift     # Liquid glass onboarding
│   │   └── ModernOnboardingWindow.swift   # Window manager
│   ├── Services/
│   │   ├── ScreenshotService.swift   # Core capture logic
│   │   └── HotKeyManager.swift       # Global hotkeys
│   ├── Utils/
│   │   └── Logger.swift              # Debug logging
│   └── *.lproj/                      # Localizations
│       └── Localizable.strings
└── SelectionWindow.swift             # Capture overlay
```

### Technologies

- **SwiftUI** : Modern interface (onboarding, preferences)
- **AppKit** : Menu bar, windows, selection overlay
- **Carbon API** : Global keyboard shortcuts
- **CGDisplayImage** : Native screen capture
- **NSPasteboard** : Clipboard management
- **UserDefaults** : Settings persistence

## 📝 Required Permissions

### Screen Recording
**Why?** To capture screen content

**How?** System Settings → Privacy & Security → Screen Recording → ✅ ScreenSnap

### Accessibility
**Why?** For global keyboard shortcut ⌥⌘S

**How?** System Settings → Privacy & Security → Accessibility → ✅ ScreenSnap

⚠️ **These permissions are automatically requested on first launch**

## ✨ Why ScreenSnap?

### vs. macOS Native Capture
| Native | ScreenSnap |
|--------|------------|
| ❌ Files accumulate on Desktop | ✅ Auto-cleanup on reboot |
| ❌ No custom shortcuts | ✅ Configurable shortcuts |
| ❌ Basic interface | ✅ Modern liquid glass onboarding |

### vs. Other Screenshot Apps
| Other Apps | ScreenSnap |
|------------|------------|
| ❌ Complex interface | ✅ Simple and fast |
| ❌ No auto-cleanup | ✅ Optimized "disposable" workflow |
| ❌ Single language | ✅ Multilingual (5 languages) |
| ❌ Cluttered Dock | ✅ Menu bar only mode |

### Developer-Optimized Workflow

```
Problem: Capture bug → Find file → Send it
Solution: ⌥⌘S → ⌘V → Already pasted in Slack!

Problem: Screenshots everywhere on Desktop
Solution: Auto-cleanup on reboot → Always clean Desktop

Problem: Complex interface with 20 options
Solution: 3 clicks max to configure, instant workflow
```

## 📄 License

MIT License - See [LICENSE](LICENSE)

## 🔗 Useful Links

- **Documentation** : [CLAUDE.md](CLAUDE.md)
- **Releases** : [GitHub Releases](https://github.com/augiefra/ScreenSnap/releases)
- **Issues** : [GitHub Issues](https://github.com/augiefra/ScreenSnap/issues)
- **Changelog** : See releases for complete history

## 🎉 Changelog

### v1.3 - Onboarding Polish (2025-01-14)

**Improved**
- 🎨 **Redesigned Onboarding Interface**
  - Increased window size from 560px to 640px for better spacing
  - Optimized layout with improved visual hierarchy
  - Better spacing between all UI elements
  - Enhanced permission request flow
- 🐛 **Bug Fixes**
  - Fixed onboarding not displaying on first launch
  - Fixed crash when closing onboarding window
  - Fixed UI overlap issues with permission buttons
- ✨ **User Experience**
  - Smoother animations and transitions
  - Better visual feedback
  - More polished overall appearance

### v1.2 - Smart Clipboard (2025-01-14)

**Added**
- 🧠 **Smart Clipboard Detection** : Automatically adapts clipboard format based on active app
  - Code editors receive file paths for Markdown linking
  - Web browsers receive image data for direct paste
  - Design tools receive image data
- 🎯 **30+ App Support** : Intelligent detection for VSCode, Zed, Cursor, Chrome, Safari, Arc, DIA, Figma, Slack, and more
- 🔍 **Fallback Strategy** : Unknown apps receive both formats for maximum compatibility

**Technical**
- App category detection using `NSWorkspace.shared.frontmostApplication`
- Smart pasteboard format selection (`.string` vs `.tiff/.png`)
- Hotkey timing optimization for accurate app detection
- Bundle ID mapping for 30+ popular applications

### v1.1 - Modern Interface (2025-01-13)

**Added**
- ✨ Modern onboarding with liquid glass effect and 4 animated pages
- 🌍 Complete multilingual support (FR/EN/ES/DE/IT)
- 🖼️ Toggle to show/hide Dock icon
- 📐 Larger preferences window (600x500)

**Improved**
- 🧹 Cleaned up preferences (removed non-functional options)
- 🎨 Onboarding interface with spring animations
- 📝 Native translations for all languages

---

**Current Version** : 1.3
**Build** : 5
**Compatibility** : macOS 13.0+ (Ventura, Sonoma, Sequoia)
**Author** : Eric COLOGNI
**License** : MIT
