import Foundation

enum AppMetadata {
    static let appName = "SwiftOrganizerX"
    static let defaultVersion = "dev"
    static let defaultBuild = "0"
    static let bundleIdentifier = "com.autogio.SwiftOrganizerX"
    
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
