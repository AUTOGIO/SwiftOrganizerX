import SwiftUI

// MARK: - App Icon
// This app is built with Swift Package Manager, which does not support asset catalogs
// directly. To add an app icon, wrap the package in an Xcode project and add an
// AppIcon asset catalog to the app target. The icon should be placed at:
//   Resources/Assets.xcassets/AppIcon.appiconset/
// within the Xcode project. A 1024×1024 source image (AppIcon-1024.png) is the
// minimum requirement; Xcode generates all required sizes automatically.

@main
struct SwiftOrganizerXApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
            CommandGroup(after: .newItem) {
                Button("Open File Organizer") {
                    NotificationCenter.default.post(name: .openFileOrganizer, object: nil)
                }
                .keyboardShortcut("O", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
