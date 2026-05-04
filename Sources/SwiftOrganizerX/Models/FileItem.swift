import Foundation

enum FileCategory: String, CaseIterable, Codable {
    case images = "Images"
    case documents = "Documents"
    case videos = "Videos"
    case audio = "Audio"
    case archives = "Archives"
    case scripts = "Scripts"
    case executables = "Executables"
    case other = "Other"
    
    var extensions: Set<String> {
        switch self {
        case .images:
            return [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp", ".svg",
                    ".heic", ".heif", ".ico"]
        case .documents:
            return [".pdf", ".docx", ".doc", ".txt", ".xlsx", ".xls", ".pptx", ".ppt",
                    ".odt", ".ods", ".odp", ".rtf", ".numbers", ".pages", ".keynote",
                    ".csv", ".md"]
        case .videos:
            return [".mp4", ".mkv", ".mov", ".avi", ".wmv", ".flv", ".webm"]
        case .audio:
            return [".mp3", ".wav", ".aac", ".flac", ".ogg", ".m4a", ".aiff", ".opus"]
        case .archives:
            return [".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz", ".iso"]
        case .scripts:
            return [".py", ".js", ".java", ".cpp", ".c", ".h", ".html", ".css", ".sh", ".bat",
                    ".swift", ".ts", ".tsx", ".jsx", ".go", ".rs", ".kt", ".rb", ".cs"]
        case .executables:
            return [".exe", ".msi", ".dmg", ".app", ".deb", ".rpm"]
        case .other:
            return []
        }
    }
    
    static func category(for extension: String) -> FileCategory {
        let ext = `extension`.lowercased()
        for category in FileCategory.allCases {
            if category.extensions.contains(ext) {
                return category
            }
        }
        return .other
    }
}

struct FileItem: Identifiable, Codable {
    let id: UUID
    let url: URL
    let name: String
    let size: Int64
    let modificationDate: Date
    let isDirectory: Bool
    
    var category: FileCategory {
        isDirectory ? .other : FileCategory.category(for: url.pathExtension.isEmpty ? "" : "." + url.pathExtension)
    }
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        
        let attributes = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        self.size = attributes[.size] as? Int64 ?? 0
        self.modificationDate = attributes[.modificationDate] as? Date ?? Date()
        self.isDirectory = (attributes[.type] as? FileAttributeType) == .typeDirectory
    }
}
