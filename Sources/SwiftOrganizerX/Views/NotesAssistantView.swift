import SwiftUI

public struct NotesAssistantView: View {
    @State private var apiKey: String = ""
    @State private var notes: [NoteItem] = []
    @State private var evaluations: [String: NoteEvaluation] = [:]
    @State private var isEvaluating: Bool = false
    @State private var processedNotes: Int = 0
    @State private var statusMessage: String = "Fetch notes to begin"
    @State private var showingConsentAlert: Bool = false
    @AppStorage(AppMetadata.aiConsentGrantedDefaultsKey) private var consentGranted: Bool = false
    private let notesService = NotesService()
    private let keychain = KeychainService()

    public var body: some View {
        VStack {
            HStack {
                Button("Fetch Notes") {
                    fetchNotes()
                }
                .buttonStyle(.borderedProminent)

                Button("Evaluate All (AI)") {
                    evaluateNotes()
                }
                .disabled(notes.isEmpty || isEvaluating || trimmedAPIKey.isEmpty)
                .buttonStyle(.bordered)

                Button("Apply Suggested Categories") {
                    applySuggestedCategories()
                }
                .disabled(isEvaluating || suggestedMoveCount == 0)
                .buttonStyle(.bordered)
            }
            .padding()

            if isEvaluating {
                ProgressView(value: Double(processedNotes), total: Double(max(notes.count, 1)))
                    .padding(.horizontal)
            }

            List(notes) { note in
                VStack(alignment: .leading) {
                    HStack {
                        Text(note.title)
                            .font(.headline)
                        Spacer()
                        if let evaluation = evaluations[note.id] {
                            Text(evaluation.isMeaningful ? "Meaningful" : "Review")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(evaluation.isMeaningful ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text(note.folder)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let evaluation = evaluations[note.id] {
                        Text(evaluation.reason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let suggestedCategory = evaluation.suggestedCategory, !suggestedCategory.isEmpty {
                            Text("Suggested folder: \(suggestedCategory)")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if !trimmedAPIKey.isEmpty {
                Text("Using configured OpenAI API key for note evaluation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Add an OpenAI API key in Settings to enable note evaluation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(statusMessage)
                .font(.caption)
                .padding()
        }
        .navigationTitle("Notes Assistant")
        .onAppear {
            apiKey = keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount) ?? ""
        }
        .alert("Send Notes to OpenAI?", isPresented: $showingConsentAlert) {
            Button("Allow") {
                consentGranted = true
                performEvaluation()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Note titles, folder names, and content will be sent to OpenAI for evaluation. OpenAI may process this data according to their privacy policy. You can revoke consent at any time in Settings.")
        }
    }

    private var trimmedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var suggestedMoveCount: Int {
        notes.reduce(into: 0) { count, note in
            guard let suggestedCategory = evaluations[note.id]?.suggestedCategory?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !suggestedCategory.isEmpty,
                  suggestedCategory != note.folder else {
                return
            }
            count += 1
        }
    }

    private func fetchNotes() {
        Task { @MainActor in
            do {
                notes = try await notesService.fetchAllNotes()
                evaluations = [:]
                processedNotes = 0
                statusMessage = "Fetched \(notes.count) notes"
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func evaluateNotes() {
        guard !trimmedAPIKey.isEmpty else {
            statusMessage = "Add an OpenAI API key in Settings before running evaluation."
            return
        }
        if consentGranted {
            performEvaluation()
        } else {
            showingConsentAlert = true
        }
    }

    private func performEvaluation() {
        Task { @MainActor in
            isEvaluating = true
            processedNotes = 0
            evaluations = [:]
            statusMessage = "Evaluating \(notes.count) notes..."

            let aiService = AIService(apiKey: trimmedAPIKey)
            var completed = 0
            var failures = 0

            for note in notes {
                do {
                    let evaluation = try await aiService.evaluate(note: note)
                    evaluations[note.id] = evaluation
                } catch {
                    failures += 1
                }

                completed += 1
                processedNotes = completed
                statusMessage = "Evaluated \(completed)/\(notes.count) notes"
            }

            isEvaluating = false
            let suggestionCount = suggestedMoveCount
            statusMessage = "Evaluation complete. \(evaluations.count) notes reviewed, \(suggestionCount) suggested moves, \(failures) failures."
        }
    }

    private func applySuggestedCategories() {
        Task { @MainActor in
            var movedCount = 0

            for note in notes {
                guard let evaluation = evaluations[note.id],
                      let suggestedCategory = evaluation.suggestedCategory?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !suggestedCategory.isEmpty,
                      suggestedCategory != note.folder else {
                    continue
                }

                do {
                    try notesService.moveNote(id: note.id, toFolder: suggestedCategory)
                    movedCount += 1
                } catch {
                    statusMessage = "Move failed for \(note.title): \(error.localizedDescription)"
                }
            }

            do {
                notes = try await notesService.fetchAllNotes()
                statusMessage = "Moved \(movedCount) notes into suggested folders."
            } catch {
                statusMessage = "Moved \(movedCount) notes, but refresh failed: \(error.localizedDescription)"
            }
        }
    }
}
