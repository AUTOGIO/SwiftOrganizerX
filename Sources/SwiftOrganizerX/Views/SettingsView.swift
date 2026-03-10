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
                Text("SwiftOrganizerX v1.0")
                Text("Native macOS File & Notes Manager")
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Settings")
    }
}
