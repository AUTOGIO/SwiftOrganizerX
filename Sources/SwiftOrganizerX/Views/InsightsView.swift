import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        VStack {
            HStack {
                Button("Select Directory for Analysis") {
                    viewModel.selectAndAnalyze()
                }
                .disabled(viewModel.isAnalyzing)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Select directory for storage analysis")
                .accessibilityHint("Analyzes file sizes and shows Pareto distribution")

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
                        .accessibilityElement(children: .combine)
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

