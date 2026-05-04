import SwiftUI

extension Notification.Name {
    static let openFileOrganizer = Notification.Name("SwiftOrganizerX.openFileOrganizer")
}

enum NavigationItem: String, CaseIterable {
    case fileOrganizer = "File Organizer"
    case notesAssistant = "Notes Assistant"
    case insights = "Insights"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .fileOrganizer: return "folder.badge.gearshape"
        case .notesAssistant: return "note.text.badge.plus"
        case .insights: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }
}

final class MainViewModel: ObservableObject {
    @Published var selectedItem: NavigationItem? = .fileOrganizer
    
    init() {}
}
