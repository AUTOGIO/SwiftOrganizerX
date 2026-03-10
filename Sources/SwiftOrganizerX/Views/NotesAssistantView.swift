import SwiftUI

public struct NotesAssistantView: View {
    @State private var notes: [NoteItem] = []
    @State private var isEvaluating: Bool = false
    @State private var statusMessage: String = "Fetch notes to begin"
    private let service = NotesService()
    
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
                .disabled(notes.isEmpty || isEvaluating)
                .buttonStyle(.bordered)
            }
            .padding()
            
            List(notes) { note in
                VStack(alignment: .leading) {
                    Text(note.title)
                        .font(.headline)
                    Text(note.folder)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(statusMessage)
                .font(.caption)
                .padding()
        }
        .navigationTitle("Notes Assistant")
    }
    
    private func fetchNotes() {
        Task {
            do {
                notes = try await service.fetchAllNotes()
                statusMessage = "Fetched \(notes.count) notes"
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func evaluateNotes() {
        // Implementation for batch AI evaluation
        statusMessage = "AI Evaluation would proceed here (OpenAI Key required)"
    }
}
