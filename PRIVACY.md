# Privacy Policy for PastScreen

**Last Updated:** November 18, 2025

## Overview

PastScreen is a privacy-first screenshot application for macOS. We take your privacy seriously and have designed the app to operate entirely on your device with zero data collection.

## Data Collection

**PastScreen collects NO personal data whatsoever.**

- No user accounts or authentication required
- No analytics or tracking
- No crash reports sent to external servers
- No telemetry or usage statistics
- No cloud storage or uploads
- No network connections (except for Sparkle auto-updates in the direct distribution version)

## Local Processing Only

All screenshot processing happens locally on your Mac:

- Screenshots are captured using macOS Screen Capture APIs
- Images are saved to your local disk (default: `~/Pictures/Screenshots/`)
- Clipboard operations use standard macOS pasteboard APIs
- All settings are stored locally in macOS UserDefaults

**Your screenshots never leave your device.**

## Required Permissions

PastScreen requires the following macOS system permissions to function:

### 1. Screen Recording
- **Purpose:** Required to capture screenshots of your screen
- **Usage:** Only activated when you trigger a screenshot capture
- **Scope:** Limited to the screen regions you explicitly select

### 2. Accessibility
- **Purpose:** Required to register global keyboard shortcuts
- **Usage:** Listens for your configured hotkey (default: ⌥⌘S)
- **Scope:** Limited to keyboard event monitoring for registered shortcuts only

### 3. Notifications (Optional)
- **Purpose:** Display confirmation notifications after screenshots
- **Usage:** Shows native macOS notifications with "Reveal in Finder" action
- **Scope:** Limited to screenshot capture confirmations

**PastScreen only uses these permissions for their stated purposes and does not access any other system resources.**

## Data Storage

Screenshots are stored locally on your Mac:

- **Default location:** `~/Pictures/Screenshots/`
- **Configurable:** You can change the save location in app preferences
- **Retention:** Files remain until you manually delete them
- **Cleanup option:** Optional "Clear on Restart" feature to automatically delete screenshots on app launch

## Third-Party Services

### Sparkle Framework (Direct Distribution Only)
The direct download version from GitHub uses Sparkle for auto-updates:
- **Purpose:** Check for app updates
- **Data sent:** macOS version, app version (no personal information)
- **Frequency:** On app launch (if enabled)
- **Open source:** [Sparkle Project](https://github.com/sparkle-project/Sparkle)

**Note:** The Mac App Store version does NOT include Sparkle and uses Apple's App Store update mechanism instead.

## Open Source

PastScreen is open source software:
- **Repository:** https://github.com/augiefra/PastScreen
- **License:** Check repository for license details
- **Transparency:** All source code is publicly auditable
- **Community:** Anyone can review, contribute, or verify privacy claims

## Children's Privacy

PastScreen does not collect any data from anyone, including children under 13. The app is rated 4+ and contains no objectionable content.

## Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be reflected in the "Last Updated" date at the top of this document and published in the GitHub repository.

## Contact

For privacy-related questions or concerns:
- **GitHub Issues:** https://github.com/augiefra/PastScreen/issues
- **Repository:** https://github.com/augiefra/PastScreen

## Your Rights

Since PastScreen collects no personal data:
- There is no data to access, modify, or delete on our end
- All your data remains on your device under your control
- You can delete the app and all its screenshots at any time
- No data remains on external servers (because none was ever sent)

---

**Summary:** PastScreen is designed with privacy as a core principle. Your screenshots, settings, and usage patterns remain entirely on your device. We don't collect, transmit, or store any of your personal information.
