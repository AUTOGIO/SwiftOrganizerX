import XCTest
@testable import SwiftOrganizerX

@MainActor
final class FileOrganizerViewModelTests: XCTestCase {

    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory, FileManager.default.fileExists(atPath: temporaryDirectory.path) {
            try FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    // MARK: - Initial State

    func testInitialState() {
        let viewModel = FileOrganizerViewModel()
        XCTAssertNil(viewModel.selectedDirectory)
        XCTAssertFalse(viewModel.isWorking)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertEqual(viewModel.statusMessage, "Select a directory to organize")
    }

    // MARK: - organize()

    func testOrganizeSetsCanUndoAndUpdatesStatusOnSuccess() async throws {
        let pdf = temporaryDirectory.appendingPathComponent("invoice.pdf")
        try Data("pdf".utf8).write(to: pdf)

        let viewModel = FileOrganizerViewModel(fileService: FileService())
        viewModel.selectedDirectory = temporaryDirectory

        viewModel.organize()

        try await waitForWorkToFinish(viewModel)

        XCTAssertFalse(viewModel.isWorking)
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertTrue(viewModel.statusMessage.contains("organized"),
                      "Status should mention organized count, got: \(viewModel.statusMessage)")
    }

    func testOrganizeDoesNothingWithoutDirectory() {
        let viewModel = FileOrganizerViewModel()
        XCTAssertNil(viewModel.selectedDirectory)
        viewModel.organize()
        XCTAssertFalse(viewModel.isWorking, "Should not start working without a directory")
    }

    func testOrganizeDoesNothingWhileAlreadyWorking() async throws {
        let viewModel = FileOrganizerViewModel()
        viewModel.selectedDirectory = temporaryDirectory
        viewModel.isWorking = true
        viewModel.organize()
        // isWorking should remain true (set externally), not flip to false immediately.
        XCTAssertTrue(viewModel.isWorking)
    }

    // MARK: - undo()

    func testUndoClearsCanUndoAfterSuccess() async throws {
        let pdf = temporaryDirectory.appendingPathComponent("report.pdf")
        try Data("pdf".utf8).write(to: pdf)

        let fileService = FileService()
        let viewModel = FileOrganizerViewModel(fileService: fileService)
        viewModel.selectedDirectory = temporaryDirectory

        viewModel.organize()
        try await waitForWorkToFinish(viewModel)
        XCTAssertTrue(viewModel.canUndo)

        viewModel.undo()
        try await waitForWorkToFinish(viewModel)

        XCTAssertFalse(viewModel.isWorking)
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertEqual(viewModel.statusMessage, "Undo successful.")
        XCTAssertTrue(FileManager.default.fileExists(atPath: pdf.path), "File should be restored")
    }

    func testUndoDoesNothingWhileWorking() {
        let viewModel = FileOrganizerViewModel()
        viewModel.isWorking = true
        viewModel.canUndo = true
        viewModel.undo()
        // Still working — undo was a no-op.
        XCTAssertTrue(viewModel.isWorking)
    }

    // MARK: - cleanEmpty()

    func testCleanEmptyRemovesEmptySubfolders() async throws {
        let emptyDir = temporaryDirectory.appendingPathComponent("EmptyFolder", isDirectory: true)
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        let viewModel = FileOrganizerViewModel(fileService: FileService())
        viewModel.selectedDirectory = temporaryDirectory

        viewModel.cleanEmpty()
        try await waitForWorkToFinish(viewModel)

        XCTAssertFalse(viewModel.isWorking)
        XCTAssertTrue(viewModel.statusMessage.contains("Removed"),
                      "Status should mention removed count, got: \(viewModel.statusMessage)")
        XCTAssertFalse(FileManager.default.fileExists(atPath: emptyDir.path),
                       "Empty folder should have been removed")
    }

    func testCleanEmptyDoesNothingWithoutDirectory() {
        let viewModel = FileOrganizerViewModel()
        viewModel.cleanEmpty()
        XCTAssertFalse(viewModel.isWorking)
    }

    // MARK: - Helpers

    /// Polls until isWorking is false (or up to 2 seconds).
    private func waitForWorkToFinish(_ viewModel: FileOrganizerViewModel) async throws {
        var attempts = 0
        while viewModel.isWorking && attempts < 40 {
            try await Task.sleep(nanoseconds: 50_000_000) // 50 ms
            attempts += 1
        }
    }
}
