import SwiftUI

public struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()

    public var body: some View {
        VStack {
            HStack {
                Button("Select Directory for Analysis") {
                    viewModel.selectAndAnalyze()
                }
                .buttonStyle(.borderedProminent)

                if viewModel.isAnalyzing {
                    ProgressView()
                        .padding(.leading, 8)
                }
            }
            .padding()

            if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if viewModel.hasAnalysis {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pareto 80/20 Analysis")
                        .font(.title2.bold())

                    Text("Top 20% of files account for \(String(format: "%.1f", viewModel.impactPercent))% of storage.")
                        .foregroundStyle(viewModel.impactPercent > 70 ? .red : .primary)

                    Divider()

                    Text("Top Storage Contributors:")
                        .font(.headline)

                    List(viewModel.topFiles) { file in
                        HStack {
                            Label(file.name, systemImage: "doc")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                        }
                    }
                }
                .padding()
            } else if !viewModel.isAnalyzing {
                ContentUnavailableView("No Data", systemImage: "chart.pie",
                                       description: Text("Select a directory to see storage insights"))
            }
        }
        .navigationTitle("Storage Insights")
    }
}

