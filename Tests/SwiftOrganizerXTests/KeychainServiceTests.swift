import XCTest
@testable import SwiftOrganizerX

/// Tests for KeychainService, including the UserDefaults→Keychain migration.
///
/// Each test instance gets a unique Keychain service name so no test touches real app
/// data and tests cannot interfere with each other. UserDefaults is cleaned up in both
/// setUp and tearDown to guard against state leaked by a previous failed run.
final class KeychainServiceTests: XCTestCase {

    private var keychain: KeychainService!

    override func setUpWithError() throws {
        // Unique service name → isolated Keychain namespace per test.
        keychain = KeychainService(service: "com.autogio.SwiftOrganizerX.tests.\(UUID().uuidString)")
        UserDefaults.standard.removeObject(forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey)
    }

    override func tearDownWithError() throws {
        try? keychain.delete(forKey: AppMetadata.openAIAPIKeyKeychainAccount)
        UserDefaults.standard.removeObject(forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey)
    }

    // MARK: - save / load / delete

    func testSaveAndLoadReturnsStoredValue() throws {
        try keychain.save("hello", forKey: AppMetadata.openAIAPIKeyKeychainAccount)
        XCTAssertEqual(keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount), "hello")
    }

    func testSaveOverwritesPreviousValue() throws {
        try keychain.save("first", forKey: AppMetadata.openAIAPIKeyKeychainAccount)
        try keychain.save("second", forKey: AppMetadata.openAIAPIKeyKeychainAccount)
        XCTAssertEqual(keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount), "second")
    }

    func testLoadReturnsNilForAbsentKey() {
        XCTAssertNil(keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount))
    }

    func testDeleteSucceedsWhenKeyIsAbsent() {
        XCTAssertNoThrow(try keychain.delete(forKey: AppMetadata.openAIAPIKeyKeychainAccount))
    }

    func testDeleteRemovesStoredValue() throws {
        try keychain.save("value", forKey: AppMetadata.openAIAPIKeyKeychainAccount)
        try keychain.delete(forKey: AppMetadata.openAIAPIKeyKeychainAccount)
        XCTAssertNil(keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount))
    }

    // MARK: - migrateAPIKeyFromUserDefaultsIfNeeded

    func testMigrationMovesLegacyKeyToKeychain() {
        UserDefaults.standard.set("sk-legacy", forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey)

        XCTAssertNil(keychain.migrateAPIKeyFromUserDefaultsIfNeeded(),
                     "Migration should return nil on success")

        XCTAssertEqual(keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount), "sk-legacy",
                       "Legacy key must be present in Keychain after migration")
        XCTAssertNil(UserDefaults.standard.string(forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey),
                     "Legacy UserDefaults entry must be removed after successful migration")
    }

    func testMigrationIsNoOpWhenNoLegacyKeyExists() {
        XCTAssertNil(keychain.migrateAPIKeyFromUserDefaultsIfNeeded())
        XCTAssertNil(keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount),
                     "Nothing should be written when there is no legacy UserDefaults entry")
    }

    func testMigrationIsNoOpForEmptyLegacyKey() {
        UserDefaults.standard.set("", forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey)
        XCTAssertNil(keychain.migrateAPIKeyFromUserDefaultsIfNeeded())
        XCTAssertNil(keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount),
                     "Empty string must be treated as absent and not migrated")
    }

    func testMigrationDoesNotOverwriteExistingKeychainValue() throws {
        // Scenario: migration ran on a previous launch, the Keychain write succeeded, but
        // the app was force-quit before the UserDefaults entry was deleted. The user then
        // updated their key via Settings (saving "sk-updated" to Keychain). On the next
        // launch the migration must NOT overwrite the newer value with the stale legacy one.
        try keychain.save("sk-updated", forKey: AppMetadata.openAIAPIKeyKeychainAccount)
        UserDefaults.standard.set("sk-legacy", forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey)

        XCTAssertNil(keychain.migrateAPIKeyFromUserDefaultsIfNeeded(),
                     "Migration should succeed (no Keychain error) even when skipping the write")

        XCTAssertEqual(keychain.load(forKey: AppMetadata.openAIAPIKeyKeychainAccount), "sk-updated",
                       "Existing Keychain value must not be overwritten by the stale legacy key")
        XCTAssertNil(UserDefaults.standard.string(forKey: AppMetadata.legacyOpenAIAPIKeyDefaultsKey),
                     "Stale UserDefaults entry must still be removed even when the write is skipped")
    }
}
