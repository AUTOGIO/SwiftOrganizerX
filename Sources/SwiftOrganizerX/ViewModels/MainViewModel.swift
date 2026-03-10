import SwiftUI

public enum NavigationItem: String, CaseIterable {
    case fileOrganizer = "File Organizer"
    case notesAssistant = "Notes Assistant"
    case insights = "Insights"
    case settings = "Settings"
    
    public var icon: String {
        switch self {
        case .fileOrganizer: return "folder.badge.gearshape"
        case .notesAssistant: return "note.text.badge.plus"
        case .insights: return "chart.bar.xaxis"
        case .settings: return "gearshape"
        }
    }
}

public final class MainViewModel: ObservableObject {
    @Published public var selectedItem: NavigationItem? = .fileOrganizer
    
    public init() {}
}
