import SwiftUI

public struct InsightsView: View {
    @StateObject private var service = FileService()
    @State private var selectedDirectory: URL?
    @State private var insights: (totalSize: Int64, topFiles: [FileItem], impactPercent: Double)?
    
    public var body: some View {
        VStack {
            Button("Select Directory for Analysis") {
                selectDirectory()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            if let insights = insights {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pareto 80/20 Analysis")
                        .font(.title2.bold())
                    
                    Text("Top 20% of files account for \(String(format: "%.1f", insights.impactPercent))% of storage.")
                        .foregroundStyle(insights.impactPercent > 70 ? .red : .primary)
                    
                    Divider()
                    
                    Text("Top Storage Contributors:")
                        .font(.headline)
                    
                    List(insights.topFiles) { file in
                        HStack {
                            Label(file.name, systemImage: "doc")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                        }
                    }
                }
                .padding()
            } else {
                ContentUnavailableView("No Data", systemImage: "chart.pie", description: Text("Select a directory to see storage insights"))
            }
        }
        .navigationTitle("Storage Insights")
    }
    
    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            selectedDirectory = panel.url
            analyze()
        }
    }
    
    private func analyze() {
        guard let url = selectedDirectory else { return }
        do {
            insights = try service.getParetoInsights(for: url)
        } catch {
            print("Analysis error: \(error)")
        }
    }
}
