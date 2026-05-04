# SwiftOrganizerX

A native macOS application for file organization and Apple Notes review, built with SwiftUI and Swift Package Manager.

**Repo:** [github.com/AUTOGIO/SwiftOrganizerX](https://github.com/AUTOGIO/SwiftOrganizerX)

## Features

- **🗂️ File Organizer**: One-click directory organization into logical categories (Images, Documents, Videos, Audio, Archives, Scripts, Executables). Supports 50+ file extensions including HEIC, HEIF, `.numbers`, `.pages`, `.keynote`, `.swift`, `.ts`, `.go`, `.rs`, and more.
- **↩️ Undo Support**: Undo the most recent file organization batch during the current app session.
- **📊 Storage Insights**: Recursive Pareto-style analysis to identify the top 20% of files consuming the most storage.
- **🧹 Cleanup**: Deep removal of empty subfolder trees (with confirmation).
- **📝 Notes Assistant**: Fetch Apple Notes, evaluate them with OpenAI GPT, and apply suggested folder categories (with confirmation).
- **🔒 Privacy-First AI**: OpenAI API key stored in Keychain. One-time consent required before sending note data to the API. Consent can be revoked at any time in Settings.
- **♿ Accessible**: Accessibility labels and hints on all major controls.
- **💻 Native UI**: Clean SwiftUI interface with Dark Mode support and standard macOS window controls.

## Environment Requirements

- **macOS 14.0+**
- **Apple Silicon or Intel Mac with Swift 5.9+**
- **OpenAI API Key**: Required for AI note evaluation. Set it in the app's Settings panel.

## Clone and Run

**One-click launch** (builds and opens the app in a single command):

```bash
git clone https://github.com/AUTOGIO/SwiftOrganizerX.git
cd SwiftOrganizerX
bash scripts/launch.sh            # debug build (fastest)
bash scripts/launch.sh release    # release build (optimised)
```

Or manually:

```bash
swift build -c release
.build/release/SwiftOrganizerX
```

## Package For Release

Build a versioned macOS `.app` bundle and `.zip` artifact:

```bash
bash scripts/package_macos_app.sh 1.1.0
```

Artifacts are written to `dist/`. For the full release flow, see `RELEASE.md`.

## Development

SwiftOrganizerX follows a modular MVVM architecture:

- **Models** (`FileItem`, `FileCategory`, `NoteItem`, `NoteEvaluation`) — pure data
- **Services** (`FileService`, `NotesService`, `AIService`, `KeychainService`) — I/O and API calls
- **ViewModels** (`FileOrganizerViewModel`, `InsightsViewModel`, `NotesAssistantViewModel`) — `@MainActor ObservableObject` state machines
- **Views** — thin SwiftUI wrappers; no business logic

All file I/O and AppleScript calls run off the main thread via `Task.detached`. UI state is always updated on the `MainActor`.

## Known Limitations

- **No app icon**: SPM-built binaries cannot embed asset catalogs directly. Wrap in an Xcode project to add an `AppIcon` asset. See the comment in `SwiftOrganizerXApp.swift`.
- **Ad-hoc code signing**: The packaging script signs with `-` (ad-hoc). For public distribution, replace with a Developer ID signature and notarize. See `RELEASE.md`.
- **Notes automation permission**: On first use of the Notes Assistant from a packaged `.app`, macOS will prompt for Automation permission. This is expected behavior — grant access to enable the feature.
- **Undo scope**: Only the most recent organize batch can be undone. Undo state is lost when the app quits.

---

Created by Antigravity for DNigga.
