# 📸 PastScreen 1.5
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

## 🆕 Version 1.5 – "Apple-first refinements"
- ✅ **App Intents + Shortcuts** for Siri and automations.
- ✅ **TipKit onboarding** in preferences.
- ✅ **Dockless notification support** (temporary Dock toggle for UN banners).
- ✅ **Selection overlay polish** with immediate first click and new dimming.

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
