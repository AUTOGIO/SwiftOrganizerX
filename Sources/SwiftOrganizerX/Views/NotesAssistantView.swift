import SwiftUI

public struct NotesAssistantView: View {
    @StateObject private var viewModel = NotesAssistantViewModel()

    public var body: some View {
        VStack {
            HStack {
                Button("Fetch Notes") {
                    viewModel.fetchNotes()
                }
                .disabled(viewModel.isFetching)
                .buttonStyle(.borderedProminent)

                Button("Evaluate All (AI)") {
                    viewModel.evaluateNotes()
                }
                .disabled(!viewModel.canEvaluate)
                .buttonStyle(.bordered)

                Button("Apply Suggested Categories") {
                    viewModel.applySuggestedCategories()
                }
                .disabled(!viewModel.canApply)
                .buttonStyle(.bordered)
            }
            .padding()

            if viewModel.isEvaluating {
                ProgressView(value: Double(viewModel.processedNotes),
                             total: Double(max(viewModel.notes.count, 1)))
                    .padding(.horizontal)
            }

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
                        }
                    }

                    Text(note.folder)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let evaluation = viewModel.evaluations[note.id] {
                        Text(evaluation.reason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let suggested = evaluation.suggestedCategory, !suggested.isEmpty {
                            Text("Suggested folder: \(suggested)")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.vertical, 4)
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
    }
}

