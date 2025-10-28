# TorchPatterns — iOS Torch Patterns (Preview‑first, Native UI)

TorchPatterns is a small SwiftUI iOS app that previews blinking torch patterns before actually enabling the device torch. Users can tune parameters, watch a live on‑screen preview, and then start the real torch. Includes a full‑screen “screen strobe” preview mode.

> Note: Simulator has no torch. Use a physical iPhone.

## Features
- Preview‑first flow: live on‑screen blinking before torch activation.
- Full‑screen screen strobe: tap the preview to mirror the pattern full‑screen (no torch).
- Patterns: Continuous, Strobe (freq/duty), Beacon, SOS.
- Safety: default 3 Hz cap with override toggle.
- Brightness control for real torch and preview intensity.
- Keeps screen awake while running (prevents auto‑lock).
- Native SwiftUI layout sized for modern 6.1" iPhones.

## Requirements
- macOS with Xcode 15+
- iOS device (iOS 16+ recommended)
- Apple ID in Xcode (free provisioning works for local installs; expires in 7 days)
- Optional: Homebrew + XcodeGen if you want to regenerate the project

## Quick Start (Xcode)
1. Open the project: `open TorchPatterns/TorchPatterns.xcodeproj`.
2. Target: select your Team under Signing, adjust `Bundle Identifier` to something unique (e.g., `com.yourname.torchpatterns`).
3. Device: connect and trust your iPhone; choose it as the run destination.
4. Run: press Cmd+R.

Result: The small preview panel blinks per settings while the torch is OFF. Tap Start to enable the actual device torch. Tap the preview to enter a full‑screen on‑screen strobe (no torch).

## CLI (optional)
- Regenerate project files (if needed):
  - `cd TorchPatterns`
  - `xcodegen generate`
- Build for generic iOS (no signing):
  - `xcodebuild -project TorchPatterns/TorchPatterns.xcodeproj -scheme TorchPatterns -configuration Debug -destination "generic/platform=iOS" CODE_SIGNING_ALLOWED=NO build`
- Build for your device (after signing in Xcode once):
  - `xcodebuild -project TorchPatterns/TorchPatterns.xcodeproj -scheme TorchPatterns -configuration Debug -destination "platform=iOS,name=<Your iPhone Name>" build`

## App Behavior & Limitations
- iOS blocks torch access in background/when the device is locked. The app prevents auto‑lock while running, but if the user locks the phone, the torch stops (by iOS design). Avoid “workarounds” that misuse background modes—they risk App Store rejection.
- Live Preview toggle hides/shows the preview area.
- Full‑screen preview is visual only (no torch), useful for demoing strobe/beacon patterns.

## Project Structure
```
TorchPatterns/
├─ project.yml
├─ TorchPatterns.xcodeproj/
└─ TorchPatterns/
   ├─ Info.plist
   ├─ TorchService.swift          # AVFoundation torch control
   ├─ PatternEngine.swift         # timing loops for patterns
   ├─ TorchViewModel.swift        # state + actions + idleTimer handling
   ├─ PatternPreviewView.swift    # compact live preview (120pt height)
   ├─ FullScreenPreviewView.swift # full‑screen on‑screen strobe
   ├─ ContentView.swift           # native, icon‑led UI
   └─ TorchPatternsApp.swift      # app entry
```

## Distributing to Users (without App Store)
- Share sources (free, easiest): recipients open in Xcode, set their Bundle ID/Team, and run on their device (expires every 7 days with free provisioning).
- TestFlight (requires paid developer account): invite up to 10k testers via link; light Apple beta review.
- Ad Hoc (paid account): collect device UDIDs, export `.ipa`, and distribute directly; no App Store review.
- Enterprise/MDM: for internal corporate distribution only.

## App Store (summary)
- Set unique `Bundle ID`, fill Version/Build, add app icon and screenshots.
- Archive (Release) → Distribute → App Store Connect → Upload.
- In App Store Connect: fill metadata, privacy, pricing; submit for review.
- Be explicit in the description: torch works only while the app is active; background/locked‑screen torch blinking is not supported by iOS.

## Safety Notice
This app can display rapid flashing patterns. Include a photosensitive epilepsy warning in your store listing and consider a first‑launch notice.

## Roadmap / Ideas
- Optional short background grace (≈30s) via `beginBackgroundTask` with safe auto‑stop.
- Additional patterns, presets, and haptics.
- Widgets/Shortcuts for quick actions.

## License
This template may be used and modified in personal or commercial apps. For open‑source distribution, pick and add a license (e.g., MIT) in a `LICENSE` file.

