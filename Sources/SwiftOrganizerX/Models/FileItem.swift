import Foundation

public enum FileCategory: String, CaseIterable, Codable {
    case images = "Images"
    case documents = "Documents"
    case videos = "Videos"
    case audio = "Audio"
    case archives = "Archives"
    case scripts = "Scripts"
    case executables = "Executables"
    case other = "Other"
    
    public var extensions: Set<String> {
        switch self {
        case .images: return [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp", ".svg"]
        case .documents: return [".pdf", ".docx", ".doc", ".txt", ".xlsx", ".xls", ".pptx", ".ppt", ".odt", ".ods", ".odp", ".rtf"]
        case .videos: return [".mp4", ".mkv", ".mov", ".avi", ".wmv", ".flv", ".webm"]
        case .audio: return [".mp3", ".wav", ".aac", ".flac", ".ogg", ".m4a"]
        case .archives: return [".zip", ".rar", ".7z", ".tar", ".gz", ".bz2"]
        case .scripts: return [".py", ".js", ".java", ".cpp", ".c", ".h", ".html", ".css", ".sh", ".bat"]
        case .executables: return [".exe", ".msi", ".dmg", ".app", ".deb", ".rpm"]
        case .other: return []
        }
    }
    
    public static func category(for extension: String) -> FileCategory {
        let ext = `extension`.lowercased()
        for category in FileCategory.allCases {
            if category.extensions.contains(ext) {
                return category
            }
        }
        return .other
    }
}

public struct FileItem: Identifiable, Codable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let size: Int64
    public let modificationDate: Date
    public let isDirectory: Bool
    
    public var category: FileCategory {
        isDirectory ? .other : FileCategory.category(for: url.pathExtension.isEmpty ? "" : "." + url.pathExtension)
    }
    
    public init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        
        let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        self.size = attributes[.size] as? Int64 ?? 0
        self.modificationDate = attributes[.modificationDate] as? Date ?? Date()
        self.isDirectory = (attributes[.type] as? FileAttributeType) == .typeDirectory
    }
}
