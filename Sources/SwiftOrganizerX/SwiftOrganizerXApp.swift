import SwiftUI

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
