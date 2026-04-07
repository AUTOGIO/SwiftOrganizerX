import XCTest
@testable import SwiftOrganizerX

final class FileServiceTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var fileService: FileService!
    
    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        fileService = FileService()
    }
    
    override func tearDownWithError() throws {
        if let temporaryDirectory, FileManager.default.fileExists(atPath: temporaryDirectory.path) {
            try FileManager.default.removeItem(at: temporaryDirectory)
        }
    }
    
    func testOrganizeMovesFilesAndUndoRestoresThem() throws {
        let imageFile = temporaryDirectory.appendingPathComponent("photo.png")
        let ignoredFile = temporaryDirectory.appendingPathComponent("notes.xyz")
        
        try Data([0x01, 0x02]).write(to: imageFile)
        try Data([0x03]).write(to: ignoredFile)
        
        let movedCount = try fileService.organize(directory: temporaryDirectory)
        
        XCTAssertEqual(movedCount, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: temporaryDirectory.appendingPathComponent("Images/photo.png").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: ignoredFile.path))
        XCTAssertEqual(fileService.lastOperations.count, 1)
        
        try fileService.undoLastOrganize()
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: imageFile.path))
        XCTAssertEqual(fileService.lastOperations.count, 0)
    }
    
    func testOrganizeCreatesUniqueDestinationName() throws {
        let sourceFile = temporaryDirectory.appendingPathComponent("report.pdf")
        let targetDirectory = temporaryDirectory.appendingPathComponent("Documents", isDirectory: true)
        let existingFile = targetDirectory.appendingPathComponent("report.pdf")
        
        try FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
        try Data("source".utf8).write(to: sourceFile)
        try Data("existing".utf8).write(to: existingFile)
        
        _ = try fileService.organize(directory: temporaryDirectory)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: targetDirectory.appendingPathComponent("report (1).pdf").path))
    }
    
    func testParetoInsightsIncludeNestedFiles() throws {
        let nestedDirectory = temporaryDirectory.appendingPathComponent("Nested", isDirectory: true)
        let largeFile = nestedDirectory.appendingPathComponent("movie.mp4")
        let smallFile = temporaryDirectory.appendingPathComponent("todo.txt")
        
        try FileManager.default.createDirectory(at: nestedDirectory, withIntermediateDirectories: true)
        try Data(repeating: 0x00, count: 100).write(to: largeFile)
        try Data(repeating: 0x00, count: 25).write(to: smallFile)
        
        let insights = try fileService.getParetoInsights(for: temporaryDirectory)
        
        XCTAssertEqual(insights.totalSize, 125)
        XCTAssertEqual(insights.topFiles.first?.name, "movie.mp4")
        XCTAssertEqual(insights.topFiles.count, 1)
        XCTAssertEqual(insights.impactPercent, 80.0, accuracy: 0.001)
    }
}
