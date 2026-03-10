import Foundation

public final class FileService: ObservableObject {
    private let fileManager = FileManager.default
    
    public struct MoveOperation: Codable {
        let source: URL
        let destination: URL
    }
    
    @Published public var lastOperations: [MoveOperation] = []
    
    public init() {}
    
    public func organize(directory: URL) throws -> Int {
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        var movedCount = 0
        var currentOperations: [MoveOperation] = []
        
        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true else { continue }
            
            let item = FileItem(url: url)
            guard item.category != .other else { continue }
            
            let targetDir = directory.appendingPathComponent(item.category.rawValue)
            if !fileManager.fileExists(atPath: targetDir.path) {
                try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
            }
            
            let destination = getUniqueURL(for: item.name, in: targetDir)
            try fileManager.moveItem(at: url, to: destination)
            
            currentOperations.append(MoveOperation(source: url, destination: destination))
            movedCount += 1
        }
        
        DispatchQueue.main.async {
            self.lastOperations = currentOperations
        }
        return movedCount
    }
    
    public func undoLastOrganize() throws {
        for op in lastOperations.reversed() {
            if fileManager.fileExists(atPath: op.destination.path) {
                try fileManager.moveItem(at: op.destination, to: op.source)
            }
        }
        DispatchQueue.main.async {
            self.lastOperations = []
        }
    }
    
    public func cleanEmptyFolders(in directory: URL) throws -> Int {
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [])
        var removedCount = 0
        
        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues.isDirectory == true {
                removedCount += try cleanEmptyFolders(in: url)
                
                let subContents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
                if subContents.isEmpty {
                    try fileManager.removeItem(at: url)
                    removedCount += 1
                }
            }
        }
        return removedCount
    }
    
    public func getParetoInsights(for directory: URL) throws -> (totalSize: Int64, topFiles: [FileItem], impactPercent: Double) {
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey], options: [.skipsHiddenFiles])
        let files = contents.compactMap { FileItem(url: $0) }.filter { !$0.isDirectory }.sorted { $0.size > $1.size }
        
        let totalSize = files.reduce(0) { $0 + $1.size }
        let topCount = max(1, Int(Double(files.count) * 0.2))
        let topFiles = Array(files.prefix(topCount))
        let topSize = topFiles.reduce(0) { $0 + $1.size }
        
        let impactPercent = totalSize > 0 ? (Double(topSize) / Double(totalSize)) * 100.0 : 0.0
        return (totalSize, topFiles, impactPercent)
    }
    
    private func getUniqueURL(for name: String, in directory: URL) -> URL {
        var destination = directory.appendingPathComponent(name)
        let baseName = destination.deletingPathExtension().lastPathComponent
        let pathExtension = destination.pathExtension
        var counter = 1
        
        while fileManager.fileExists(atPath: destination.path) {
            let newName = "\(baseName) (\(counter))" + (pathExtension.isEmpty ? "" : ".\(pathExtension)")
            destination = directory.appendingPathComponent(newName)
            counter += 1
        }
        return destination
    }
}
