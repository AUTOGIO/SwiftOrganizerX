# SwiftOrganizerX

A production-ready, native macOS application for automated file and notes management, optimized for Apple Silicon (M3).

**Repo:** [github.com/AUTOGIO/SwiftOrganizerX](https://github.com/AUTOGIO/SwiftOrganizerX)

## Features

- **🗂️ File Organizer**: One-click directory organization into logical categories.
- **↩️ Undo Support**: Robust undo system for organization operations.
- **📊 Storage Insights**: Pareto 80/20 analysis to identify storage bloat.
- **🧹 Cleanup**: Deep removal of empty subfolder trees.
- **📝 Notes Assistant**: Intelligent Apple Notes categorization and cleanup powered by OpenAI.
- **💻 Native UI**: Clean, efficient SwiftUI interface with Dark Mode support.

## Environment Requirements

- **macOS 14.0+**
- **Apple Silicon (M3 Optimized)**
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

## Development

SwiftOrganizerX follows a modular MVVM architecture. Core logic is isolated in the `Services` layer, and the UI is built entirely with SwiftUI.

---
Created by Antigravity for DNigga.
