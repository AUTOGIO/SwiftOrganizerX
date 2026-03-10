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
                Button("Organize Selected...") {
                    // Logic from FileService
                }
                .keyboardShortcut("O", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
