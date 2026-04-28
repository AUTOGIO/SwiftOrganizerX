import Foundation
#if canImport(Security)
import Security
#endif

/// Provides secure storage for sensitive string values (e.g. API keys) using the system Keychain.
///
/// All operations are no-ops on platforms where the Security framework is unavailable.
final class KeychainService {
    private let service: String

    init(service: String = AppMetadata.bundleIdentifier) {
        self.service = service
    }

    /// Saves (or replaces) a UTF-8 string in the Keychain for the given account key.
    func save(_ value: String, forKey account: String) throws {
        #if canImport(Security)
        let data = Data(value.utf8)
        // Delete any existing item first so SecItemAdd always succeeds.
        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
        #endif
    }

    /// Loads and returns the stored string for the given account key, or `nil` if not found.
    func load(forKey account: String) -> String? {
        #if canImport(Security)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
        #else
        return nil
        #endif
    }

    /// Removes the Keychain item for the given account key. Succeeds silently when the item
    /// does not exist.
    func delete(forKey account: String) throws {
        #if canImport(Security)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        #endif
    }

    /// Performs a one-time migration of a legacy plaintext API key from UserDefaults into the
    /// Keychain. Safe to call on every launch: is a no-op when no legacy key exists.
    /// The UserDefaults entry is removed only after a successful Keychain write, so the key is
    /// never silently lost on a save failure.
    ///
    /// - Returns: The error if the Keychain write failed (caller may surface it); `nil` on success
    ///   or when there was nothing to migrate.
    @discardableResult
    func migrateAPIKeyFromUserDefaultsIfNeeded() -> Error? {
        let defaults = UserDefaults.standard
        guard let legacy = defaults.string(forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey),
              !legacy.isEmpty else { return nil }
        do {
            try save(legacy, forKey: AppMetadata.openAIAPIKeyKeychainAccount)
            defaults.removeObject(forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey)
            return nil
        } catch {
            return error
        }
    }

    enum KeychainError: LocalizedError {
        case saveFailed(Int32)
        case deleteFailed(Int32)

        var errorDescription: String? {
            switch self {
            case .saveFailed(let s): return "Keychain save failed (OSStatus \(s))."
            case .deleteFailed(let s): return "Keychain delete failed (OSStatus \(s))."
            }
        }
    }
}
