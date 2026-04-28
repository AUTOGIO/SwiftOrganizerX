import SwiftUI

public struct NotesAssistantView: View {
    @StateObject private var viewModel = NotesAssistantViewModel()
    @State private var showApplyConfirmation = false

    public var body: some View {
        VStack {
            HStack {
                Button("Fetch Notes") {
                    viewModel.fetchNotes()
                }
                .disabled(viewModel.isFetching)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Fetch notes from Apple Notes")
                .accessibilityHint("Loads all notes via AppleScript")

                Button("Evaluate All (AI)") {
                    viewModel.evaluateNotes()
                }
                .disabled(!viewModel.canEvaluate)
                .buttonStyle(.bordered)
                .accessibilityLabel("Evaluate notes with AI")
                .accessibilityHint("Sends notes to OpenAI for categorization suggestions")

                Button("Apply Suggested Categories") {
                    showApplyConfirmation = true
                }
                .disabled(!viewModel.canApply)
                .buttonStyle(.bordered)
                .accessibilityLabel("Apply suggested category moves")
                .accessibilityHint("Moves \(viewModel.suggestedMoveCount) note(s) into their suggested folders")
            }
            .padding()

            if viewModel.isEvaluating {
                ProgressView(value: Double(viewModel.processedNotes),
                             total: Double(max(viewModel.notes.count, 1)))
                    .padding(.horizontal)
                    .accessibilityLabel("Evaluation progress")
                    .accessibilityValue("\(viewModel.processedNotes) of \(viewModel.notes.count) notes evaluated")
            }

            if viewModel.isApplying {
                ProgressView("Applying changes…")
                    .padding(.horizontal)
            }

            if viewModel.notes.isEmpty {
                ContentUnavailableView(
                    "No Notes",
                    systemImage: "note.text",
                    description: Text("Tap \"Fetch Notes\" to load your Apple Notes library")
                )
            } else {
                List(viewModel.notes) { note in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(note.title)
                                .font(.headline)
                            Spacer()
                            if let evaluation = viewModel.evaluations[note.id] {
                                Text(evaluation.isMeaningful ? "Meaningful" : "Review")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(evaluation.isMeaningful
                                        ? Color.green.opacity(0.15)
                                        : Color.orange.opacity(0.15))
                                    .clipShape(Capsule())
                                    .accessibilityLabel(evaluation.isMeaningful ? "Meaningful note" : "Needs review")
                            }
                        }

                        Text(note.folder)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Current folder: \(note.folder)")

                        if let evaluation = viewModel.evaluations[note.id] {
                            Text(evaluation.reason)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let suggested = evaluation.suggestedCategory, !suggested.isEmpty {
                                Text("Suggested folder: \(suggested)")
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .accessibilityLabel("Suggested folder: \(suggested)")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }

            if !viewModel.trimmedAPIKey.isEmpty {
                Text("Using configured OpenAI API key for note evaluation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Add an OpenAI API key in Settings to enable note evaluation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(viewModel.statusMessage)
                .font(.caption)
                .padding()
        }
        .navigationTitle("Notes Assistant")
        .onAppear {
            viewModel.onAppear()
        }
        .alert("Send Notes to OpenAI?", isPresented: $viewModel.showConsentAlert) {
            Button("Allow") {
                viewModel.grantConsentAndEvaluate()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Note titles, folder names, and content will be sent to OpenAI for evaluation. OpenAI may process this data according to their privacy policy. You can revoke consent at any time in Settings.")
        }
        .alert("Apply \(viewModel.suggestedMoveCount) Suggested Move(s)?",
               isPresented: $showApplyConfirmation) {
            Button("Apply", role: .destructive) {
                viewModel.applySuggestedCategories()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will move \(viewModel.suggestedMoveCount) note(s) into their suggested folders in Apple Notes. You can move them back manually if needed.")
        }
    }
}

