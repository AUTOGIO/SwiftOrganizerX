import SwiftUI

public struct FileOrganizerView: View {
    @StateObject private var viewModel = FileOrganizerViewModel()

    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(viewModel.selectedDirectory?.path ?? "No directory selected")
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button("Select Directory") {
                    viewModel.selectDirectory()
                }
                .buttonStyle(.borderedProminent)
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

                Button {
                    viewModel.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!viewModel.canUndo || viewModel.isWorking)

                Button {
                    viewModel.cleanEmpty()
                } label: {
                    Label("Clean Empty", systemImage: "trash")
                }
                .disabled(viewModel.selectedDirectory == nil || viewModel.isWorking)
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
    }
}

