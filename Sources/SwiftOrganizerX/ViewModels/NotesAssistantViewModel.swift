import Foundation
import SwiftUI

/// Owns all state and business logic for the Notes Assistant feature.
///
/// Threading model:
/// - All @Published state is read/written on the MainActor.
/// - Notes fetching and note-move operations are dispatched via Task.detached so that
///   the blocking NSAppleScript call never runs on the main thread.
/// - AI evaluation uses a bounded TaskGroup (up to `evaluationConcurrency` concurrent
///   requests) so large notes libraries don't overwhelm the OpenAI API.
@MainActor
public final class NotesAssistantViewModel: ObservableObject {

    // MARK: - Published State

    @Published public var notes: [NoteItem] = []
    @Published public var evaluations: [String: NoteEvaluation] = [:]
    @Published public var isFetching: Bool = false
    @Published public var isEvaluating: Bool = false
    @Published public var isApplying: Bool = false
    @Published public var processedNotes: Int = 0
    @Published public var statusMessage: String = "Fetch notes to begin"
    @Published public var showConsentAlert: Bool = false
    /// Loaded from Keychain on onAppear; not persisted here.
    @Published public var apiKey: String = ""

    @AppStorage(AppMetadata.aiConsentGrantedDefaultsKey) public var consentGranted: Bool = false

    // MARK: - Dependencies

    private let notesService: NotesService
    private let keychain: KeychainService

    // MARK: - Constants

    /// Maximum number of concurrent OpenAI evaluation requests.
    private static let evaluationConcurrency = 3

    // MARK: - Init

    public init(notesService: NotesService = NotesService(),
                keychain: KeychainService = KeychainService()) {
        self.notesService = notesService
        self.keychain = keychain
    }

    // MARK: - Computed

    public var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var suggestedMoveCount: Int {
        notes.reduce(into: 0) { count, note in
            guard let suggested = evaluations[note.id]?.suggestedCategory?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !suggested.isEmpty,
                  suggested != note.folder else { return }
            count += 1
        }
    }

    public var canEvaluate: Bool {
        !notes.isEmpty && !isEvaluating && !isFetching && !trimmedAPIKey.isEmpty
    }

    public var canApply: Bool {
        !isEvaluating && !isApplying && !isFetching && suggestedMoveCount > 0
    }

    // MARK: - Lifecycle

    public func onAppear() {
        // Uses the shared migration helper to avoid duplicating migration logic.
        // Surface migration failures in statusMessage so the user knows to re-enter the key.
        if let error = keychain.migrateAPIKeyFromUserDefaultsIfNeeded() {
            statusMessage = "Key migration failed: \(error.localizedDescription)"
        }
        apiKey = keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount) ?? ""
    }

    // MARK: - Actions

    /// Fetches all notes from Apple Notes via AppleScript on a background thread.
    public func fetchNotes() {
        guard !isFetching else { return }
        isFetching = true
        statusMessage = "Fetching notes..."
        let service = notesService
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let fetched = try await service.fetchAllNotes()
                await MainActor.run {
                    self?.notes = fetched
                    self?.evaluations = [:]
                    self?.processedNotes = 0
                    self?.isFetching = false
                    self?.statusMessage = "Fetched \(fetched.count) notes"
                }
            } catch {
                await MainActor.run {
                    self?.isFetching = false
                    self?.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Entry point for AI evaluation. Shows the consent alert on first use.
    public func evaluateNotes() {
        guard !trimmedAPIKey.isEmpty else {
            statusMessage = "Add an OpenAI API key in Settings before running evaluation."
            return
        }
        if consentGranted {
            Task { await performEvaluation() }
        } else {
            showConsentAlert = true
        }
    }

    /// Called when the user taps "Allow" in the consent alert.
    public func grantConsentAndEvaluate() {
        consentGranted = true
        Task { await performEvaluation() }
    }

    /// Moves each note with a suggested category into that folder, then refreshes.
    public func applySuggestedCategories() {
        guard !isApplying else { return }
        isApplying = true
        let capturedNotes = notes
        let capturedEvaluations = evaluations
        let service = notesService
        Task.detached(priority: .userInitiated) { [weak self] in
            var movedCount = 0
            var lastMoveError: String?
            for note in capturedNotes {
                guard let evaluation = capturedEvaluations[note.id],
                      let suggested = evaluation.suggestedCategory?
                          .trimmingCharacters(in: .whitespacesAndNewlines),
                      !suggested.isEmpty,
                      suggested != note.folder else { continue }
                do {
                    try service.moveNote(id: note.id, toFolder: suggested)
                    movedCount += 1
                } catch {
                    lastMoveError = "Move failed for \(note.title): \(error.localizedDescription)"
                }
            }
            do {
                let refreshed = try await service.fetchAllNotes()
                await MainActor.run {
                    self?.notes = refreshed
                    self?.isApplying = false
                    self?.statusMessage = "Moved \(movedCount) notes into suggested folders."
                }
            } catch {
                await MainActor.run {
                    self?.isApplying = false
                    self?.statusMessage = lastMoveError
                        ?? "Moved \(movedCount) notes, but refresh failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Private

    /// Runs AI evaluation with bounded concurrency (up to `evaluationConcurrency` requests
    /// in flight simultaneously). Progress counters and per-note results are updated on the
    /// MainActor as each result arrives. Individual note failures do not cancel the batch.
    private func performEvaluation() async {
        isEvaluating = true
        processedNotes = 0
        evaluations = [:]
        statusMessage = "Evaluating \(notes.count) notes..."

        let capturedNotes = notes
        let aiService = AIService(apiKey: trimmedAPIKey)
        var completed = 0
        var failures = 0

        await withTaskGroup(of: (String, Result<NoteEvaluation, Error>).self) { group in
            var iterator = capturedNotes.makeIterator()
            var inFlight = 0

            // Seed the initial batch up to the concurrency limit.
            while inFlight < Self.evaluationConcurrency, let note = iterator.next() {
                group.addTask {
                    do { return (note.id, .success(try await aiService.evaluate(note: note))) }
                    catch { return (note.id, .failure(error)) }
                }
                inFlight += 1
            }

            // Drain completed results and immediately refill the pool.
            for await (id, result) in group {
                inFlight -= 1
                completed += 1
                switch result {
                case .success(let evaluation):
                    evaluations[id] = evaluation
                case .failure:
                    failures += 1
                }
                processedNotes = completed
                statusMessage = "Evaluated \(completed)/\(capturedNotes.count) notes"

                if let next = iterator.next() {
                    group.addTask {
                        do { return (next.id, .success(try await aiService.evaluate(note: next))) }
                        catch { return (next.id, .failure(error)) }
                    }
                    inFlight += 1
                }
            }
        }

        isEvaluating = false
        statusMessage = "Evaluation complete. \(evaluations.count) notes reviewed, "
            + "\(suggestedMoveCount) suggested moves, \(failures) failures."
    }
}
