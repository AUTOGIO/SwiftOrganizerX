import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    
    init() {}
    
    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, id: \.self, selection: $viewModel.selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                }
            }
            .navigationTitle("SwiftOrganizerX")
        } detail: {
            if let selectedItem = viewModel.selectedItem {
                switch selectedItem {
                case .fileOrganizer:
                    FileOrganizerView()
                case .notesAssistant:
                    NotesAssistantView()
                case .insights:
                    InsightsView()
                case .settings:
                    SettingsView()
                }
            } else {
                ContentUnavailableView(
                    "No Section Selected",
                    systemImage: "sidebar.left",
                    description: Text("Choose a section from the sidebar to get started")
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFileOrganizer)) { _ in
            viewModel.selectedItem = .fileOrganizer
        }
    }
}
