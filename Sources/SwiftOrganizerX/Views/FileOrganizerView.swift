import SwiftUI

struct FileOrganizerView: View {
    @StateObject private var viewModel = FileOrganizerViewModel()
    @State private var showCleanEmptyConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(viewModel.selectedDirectory?.path ?? "No directory selected")
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button("Select Directory") {
                    viewModel.selectDirectory()
                }
                .disabled(viewModel.isWorking)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Select directory to organize")
                .accessibilityHint("Opens a folder picker")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)

            HStack(spacing: 15) {
                Button {
                    viewModel.organize()
                } label: {
                    Label("Organize", systemImage: "folder.badge.plus")
                }
                .disabled(viewModel.selectedDirectory == nil || viewModel.isWorking)
                .accessibilityLabel("Organize files")
                .accessibilityHint("Moves files into category subfolders")

                Button {
                    viewModel.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!viewModel.canUndo || viewModel.isWorking)
                .accessibilityLabel("Undo last organize")
                .accessibilityHint("Restores files to their original locations")

                Button {
                    showCleanEmptyConfirmation = true
                } label: {
                    Label("Clean Empty", systemImage: "trash")
                }
                .disabled(viewModel.selectedDirectory == nil || viewModel.isWorking)
                .accessibilityLabel("Remove empty folders")
                .accessibilityHint("Permanently deletes all empty subfolders")
            }
            .buttonStyle(.bordered)

            if viewModel.isWorking {
                ProgressView()
                    .padding(.vertical, 4)
            }

            Divider()

            VStack(alignment: .leading) {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView {
                    Text(viewModel.statusMessage)
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
        .alert("Remove Empty Folders?", isPresented: $showCleanEmptyConfirmation) {
            Button("Remove", role: .destructive) {
                viewModel.cleanEmpty()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all empty subfolders inside the selected directory. This cannot be undone.")
        }
    }
}

