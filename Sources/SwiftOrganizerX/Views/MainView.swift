import SwiftUI

public struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    
    public init() {}
    
    public var body: some View {
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
                Text("Select an item from the sidebar")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
