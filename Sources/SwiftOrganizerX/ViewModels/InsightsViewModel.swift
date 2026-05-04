import Foundation
import AppKit

/// Owns all state and business logic for the Storage Insights feature.
/// Directory enumeration is dispatched off the main thread via Task.detached;
/// all @Published state updates are made back on the MainActor.
@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var totalSize: Int64 = 0
    @Published var topFiles: [FileItem] = []
    @Published var impactPercent: Double = 0.0
    @Published var hasAnalysis: Bool = false
    @Published var isAnalyzing: Bool = false
    @Published var statusMessage: String = ""

    private let fileService: FileService

    init(fileService: FileService = FileService()) {
        self.fileService = fileService
    }

    // MARK: - Actions

    func selectAndAnalyze() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            analyze(url)
        }
    }

    // MARK: - Private

    private func analyze(_ url: URL) {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        hasAnalysis = false
        statusMessage = ""
        let service = fileService
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let result = try service.getParetoInsights(for: url)
                await MainActor.run {
                    self?.totalSize = result.totalSize
                    self?.topFiles = result.topFiles
                    self?.impactPercent = result.impactPercent
                    self?.hasAnalysis = true
                    self?.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self?.isAnalyzing = false
                    self?.statusMessage = "Analysis error: \(error.localizedDescription)"
                }
            }
        }
    }
}
