import Foundation

enum AppMetadata {
    static let appName = "SwiftOrganizerX"
    static let defaultVersion = "dev"
    static let defaultBuild = "0"
    static let bundleIdentifier = "com.autogio.SwiftOrganizerX"

    // MARK: - Storage Keys

    /// Keychain account name used to store the OpenAI API key.
    static let openAIAPIKeyKeychainAccount = "openai_api_key"
    /// Legacy UserDefaults key used before Keychain migration. Checked once on first launch.
    static let legacyOpenAIAPIKeyDefaultsKey = "openai_api_key"
    /// UserDefaults key persisting whether the user has granted AI evaluation consent.
    static let aiConsentGrantedDefaultsKey = "ai_consent_granted"

    static var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? appName
    }
    
    static var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? defaultVersion
    }
    
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? defaultBuild
    }
    
    static var versionLabel: String {
        "v\(shortVersion) (\(buildNumber))"
    }
}
