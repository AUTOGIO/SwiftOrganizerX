# SwiftOrganizerX

A native macOS application for file organization and Apple Notes review, built with SwiftUI and Swift Package Manager.

**Repo:** [github.com/AUTOGIO/SwiftOrganizerX](https://github.com/AUTOGIO/SwiftOrganizerX)

## Features

- **🗂️ File Organizer**: One-click directory organization into logical categories.
- **↩️ Undo Support**: Undo the most recent file organization batch during the current app session.
- **📊 Storage Insights**: Recursive Pareto-style analysis to identify storage-heavy files.
- **🧹 Cleanup**: Deep removal of empty subfolder trees.
- **📝 Notes Assistant**: Fetch Apple Notes, evaluate them with OpenAI, and apply suggested folder categories.
- **💻 Native UI**: Clean, efficient SwiftUI interface with Dark Mode support.

## Environment Requirements

- **macOS 14.0+**
- **Apple Silicon or Intel Mac with Swift 5.9+**
- **OpenAI API Key**: Set in the app settings for AI features.

## Clone and Run

```bash
git clone https://github.com/AUTOGIO/SwiftOrganizerX.git
cd SwiftOrganizerX
swift build -c release
.build/release/SwiftOrganizerX
```

## Build and Run

1. Open the project in Xcode or use the Swift Package Manager.
2. Build the project:
   ```bash
   swift build -c release
   ```
3. Run the application:
   ```bash
   .build/release/SwiftOrganizerX
   ```

## Package For Release

Build a versioned macOS `.app` bundle and `.zip` artifact:

```bash
bash scripts/package_macos_app.sh 1.0.0
```

Artifacts are written to `dist/`.

For the manual release flow, see `RELEASE.md`.

## Development

SwiftOrganizerX follows a modular MVVM architecture. Core logic is isolated in the `Services` layer, and the UI is built entirely with SwiftUI.

---
Created by Antigravity for DNigga.
