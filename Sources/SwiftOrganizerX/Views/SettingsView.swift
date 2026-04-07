import SwiftUI

public struct SettingsView: View {
    @AppStorage("openai_api_key") private var apiKey: String = ""
    
    public var body: some View {
        Form {
            Section("API Configuration") {
                SecureField("OpenAI API Key", text: $apiKey)
                Text("Required for AI Notes evaluation and categorization.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("About") {
                Text("\(AppMetadata.displayName) \(AppMetadata.versionLabel)")
                Text("Native macOS File & Notes Manager")
                Text(AppMetadata.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Settings")
    }
}
