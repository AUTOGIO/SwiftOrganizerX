import SwiftUI

public struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var saveError: String?
    @AppStorage(AppMetadata.aiConsentGrantedDefaultsKey) private var consentGranted: Bool = false
    private let keychain = KeychainService()

    public var body: some View {
        Form {
            Section("API Configuration") {
                SecureField("OpenAI API Key", text: $apiKey)
                    .onChange(of: apiKey) { _, newValue in
                        saveAPIKey(newValue)
                    }
                Text("Required for AI Notes evaluation and categorization.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let error = saveError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Privacy") {
                Toggle("AI evaluation consent granted", isOn: $consentGranted)
                Text("When enabled, note titles, folder names, and content may be sent to OpenAI for evaluation. Disable to revoke consent and be prompted again before the next evaluation.")
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
        .onAppear {
            loadAndMigrateAPIKey()
        }
    }

    // MARK: - Private helpers

    private func loadAndMigrateAPIKey() {
        // One-time migration: move the legacy plaintext key from UserDefaults into the Keychain.
        // Only removes the UserDefaults entry if the Keychain write succeeds, so the key is
        // never silently lost on save failure.
        let defaults = UserDefaults.standard
        if let legacy = defaults.string(forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey),
           !legacy.isEmpty {
            do {
                try keychain.save(legacy, forKey: AppMetadata.openAIAPIKeyKeychainAccount)
                defaults.removeObject(forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey)
            } catch {
                // Leave UserDefaults key intact so the next launch can retry migration.
                saveError = "Key migration failed: \(error.localizedDescription)"
            }
        }
        apiKey = keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount) ?? ""
    }

    private func saveAPIKey(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if trimmed.isEmpty {
                try keychain.delete(forKey: AppMetadata.openAIAPIKeyKeychainAccount)
            } else {
                try keychain.save(trimmed, forKey: AppMetadata.openAIAPIKeyKeychainAccount)
            }
            saveError = nil
        } catch {
            saveError = error.localizedDescription
        }
    }
}
