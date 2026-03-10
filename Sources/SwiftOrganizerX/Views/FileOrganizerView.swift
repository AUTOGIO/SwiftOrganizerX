import SwiftUI

public struct FileOrganizerView: View {
    @StateObject private var service = FileService()
    @State private var selectedDirectory: URL?
    @State private var statusMessage: String = "Select a directory to organize"
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(selectedDirectory?.path ?? "No directory selected")
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Button("Select Directory") {
                    selectDirectory()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
            
            HStack(spacing: 15) {
                Button(action: organize) {
                    Label("Organize", systemImage: "folder.badge.plus")
                }
                .disabled(selectedDirectory == nil)
                
                Button(action: undo) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(service.lastOperations.isEmpty)
                
                Button(action: cleanEmpty) {
                    Label("Clean Empty", systemImage: "trash")
                }
                .disabled(selectedDirectory == nil)
            }
            .buttonStyle(.bordered)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ScrollView {
                    Text(statusMessage)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(5)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(5)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("File Organizer")
    }
    
    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            selectedDirectory = panel.url
        }
    }
    
    private func organize() {
        guard let url = selectedDirectory else { return }
        do {
            let count = try service.organize(directory: url)
            statusMessage = "Successfully organized \(count) files."
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    private func undo() {
        do {
            try service.undoLastOrganize()
            statusMessage = "Undo successful."
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    private func cleanEmpty() {
        guard let url = selectedDirectory else { return }
        do {
            let count = try service.cleanEmptyFolders(in: url)
            statusMessage = "Removed \(count) empty folders."
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
}
