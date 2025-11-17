# 📸 PastScreen
**Ultra-fast, clipboard-first screenshots for developers on macOS.**

[![Version](https://img.shields.io/badge/version-1.5-blue.svg)](https://github.com/augiefra/PastScreen/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%2014+-lightgrey.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![Sparkle](https://img.shields.io/badge/updates-Sparkle%202.8-green.svg)](https://sparkle-project.org/)

> Capture any region in milliseconds, copy it directly to your clipboard, and keep coding.

---

## ✨ Highlights
- **Instant clipboard**: Every capture is immediately available as PNG + file path, optimized per app (VSCode/Zed/Cursor, browsers, design tools…).
- **Menu bar native**: Clean macOS menu-bar app with a simple menu, global hotkey (⌥⌘S) and optional Dock icon.
- **Liquid Glass overlay**: Custom selection window with translucent HUD styling and precise dimming.
- **Apple-native notifications**: UN notifications with Finder reveal, silent banners, and a "Saved" pill in the menu bar.
- **Sparkle auto-updates**: Secure updates delivered via Sparkle 2.8 with EdDSA signatures.
- **Shortcuts & Siri ready** (1.5): Capture area/full screen through App Intents, Automation and Spotlight.

---

## 🆕 Version 1.6 – "Apple-first refinements + bug corrections"
✨ What's New
- Multi-monitor capture fixes – ScreenCaptureKit now receives coordinates relative to the correct display, eliminating shifted/pixelated captures and “invalid parameter” errors.
- Reliable overlay – The Liquid Glass overlay converts selections into global coordinates correctly and cleans up even when cancellations happen quickly.
- Smarter clipboard – Browsers/design tools get the image plus a fallback file path, while editors like Zed/VSCode continue to receive the path-only experience when appropriate.
- Outlook support – Outlook is now treated as a browser, so captures triggered from it paste the full image by default.
🐛 Bug Fixes
- Fixed a bug where a second instance could launch when running from Xcode.
- Removed inconsistent DPI metadata that made captures look zoomed in Quick Look.
- Cleaned up the release pipeline and included the Sparkle packaging script.

See full changelog in [`appcast.xml`](appcast.xml) or the [GitHub Releases](https://github.com/augiefra/PastScreen/releases).

---

## 🧩 Tech Stack
- **Swift 5.9**, AppKit + SwiftUI hybrid UI.
- **ScreenCaptureKit** for safe, high-quality captures.
- **Sparkle 2.8** for auto-updates.
- **TipKit & AppIntents** (macOS 14+)
- Localization: en, fr, es, de, it.

---

## 🔐 Permissions
| Permission | Usage |
|------------|-------|
| Screen Recording | Required for ScreenCaptureKit to read pixels. |
| Accessibility | Needed for the global ⌥⌘S hotkey. |
| Notifications | Banners + Finder reveal after each capture. |

PastScreen never uploads or transmits captures. All operations run locally.

---

## 🛠 Development Workflow
- Active work happens on [`PastScreen-dev`](https://github.com/augiefra/PastScreen-dev).
- Public releases (Sparkle + binaries) live on [`PastScreen`](https://github.com/augiefra/PastScreen).

---

## 🙌 Credits & License
Built by **(@augiefra)** for developers needing instant, reliable screenshots. Licensed under the [MIT License](LICENSE).

Contributions welcome! File issues, discuss ideas, or propose PRs. Enjoy lightning-fast screenshots. ⚡️
