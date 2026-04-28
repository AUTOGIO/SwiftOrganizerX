import Foundation
import AppKit

/// Owns all state and business logic for the File Organizer feature.
/// File I/O is dispatched off the main thread via Task.detached; all
/// @Published state updates are made back on the MainActor.
@MainActor
public final class FileOrganizerViewModel: ObservableObject {
    @Published public var selectedDirectory: URL?
    @Published public var statusMessage: String = "Select a directory to organize"
    @Published public var isWorking: Bool = false
    @Published public var canUndo: Bool = false

    private let fileService: FileService

    public init(fileService: FileService = FileService()) {
        self.fileService = fileService
    }

    // MARK: - Actions

    public func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            selectedDirectory = panel.url
        }
    }

    public func organize() {
        guard let url = selectedDirectory, !isWorking else { return }
        isWorking = true
        let service = fileService
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let count = try service.organize(directory: url)
                let hasOps = !service.lastOperations.isEmpty
                await MainActor.run {
                    self?.isWorking = false
                    self?.canUndo = hasOps
                    self?.statusMessage = "Successfully organized \(count) files."
                }
            } catch {
                let hasOps = !service.lastOperations.isEmpty
                await MainActor.run {
                    self?.isWorking = false
                    self?.canUndo = hasOps
                    self?.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func undo() {
        guard !isWorking else { return }
        isWorking = true
        let service = fileService
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                try service.undoLastOrganize()
                await MainActor.run {
                    self?.isWorking = false
                    self?.canUndo = false
                    self?.statusMessage = "Undo successful."
                }
            } catch {
                let hasOps = !service.lastOperations.isEmpty
                await MainActor.run {
                    self?.isWorking = false
                    self?.canUndo = hasOps
                    self?.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func cleanEmpty() {
        guard let url = selectedDirectory, !isWorking else { return }
        isWorking = true
        let service = fileService
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let count = try service.cleanEmptyFolders(in: url)
                await MainActor.run {
                    self?.isWorking = false
                    self?.statusMessage = "Removed \(count) empty folders."
                }
            } catch {
                await MainActor.run {
                    self?.isWorking = false
                    self?.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
