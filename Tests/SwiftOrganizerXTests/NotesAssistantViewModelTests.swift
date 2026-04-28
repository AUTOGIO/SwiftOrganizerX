import XCTest
@testable import SwiftOrganizerX

/// Tests the synchronous / pure-logic paths of NotesAssistantViewModel.
/// AI evaluation and AppleScript execution are not invoked in these tests.
@MainActor
final class NotesAssistantViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let viewModel = NotesAssistantViewModel()
        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertTrue(viewModel.evaluations.isEmpty)
        XCTAssertFalse(viewModel.isFetching)
        XCTAssertFalse(viewModel.isEvaluating)
        XCTAssertFalse(viewModel.isApplying)
        XCTAssertEqual(viewModel.processedNotes, 0)
        XCTAssertEqual(viewModel.statusMessage, "Fetch notes to begin")
        XCTAssertFalse(viewModel.showConsentAlert)
        XCTAssertTrue(viewModel.apiKey.isEmpty)
    }

    // MARK: - Consent Gate

    func testEvaluateNotesShowsConsentAlertWhenNotGranted() {
        let viewModel = NotesAssistantViewModel()
        viewModel.notes = [NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")]
        viewModel.apiKey = "sk-test-key"
        viewModel.consentGranted = false

        viewModel.evaluateNotes()

        XCTAssertTrue(viewModel.showConsentAlert,
                      "Consent alert should show when consent has not been granted")
        XCTAssertFalse(viewModel.isEvaluating, "Evaluation should not start without consent")
    }

    func testEvaluateNotesDoesNotShowAlertWhenConsentAlreadyGranted() {
        let viewModel = NotesAssistantViewModel()
        viewModel.notes = [NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")]
        viewModel.apiKey = "sk-test-key"
        viewModel.consentGranted = true

        viewModel.evaluateNotes()

        XCTAssertFalse(viewModel.showConsentAlert,
                       "Consent alert should not show when consent is already granted")
    }

    func testGrantConsentAndEvaluateSetsConsentGranted() {
        let viewModel = NotesAssistantViewModel()
        viewModel.consentGranted = false

        viewModel.grantConsentAndEvaluate()

        XCTAssertTrue(viewModel.consentGranted, "Granting consent should set consentGranted to true")
    }

    // MARK: - API Key Guard

    func testEvaluateNotesWithEmptyKeyUpdatesStatusMessage() {
        let viewModel = NotesAssistantViewModel()
        viewModel.notes = [NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")]
        viewModel.apiKey = ""

        viewModel.evaluateNotes()

        XCTAssertFalse(viewModel.showConsentAlert)
        XCTAssertFalse(viewModel.isEvaluating)
        XCTAssertTrue(viewModel.statusMessage.contains("API key"),
                      "Status should mention API key requirement, got: \(viewModel.statusMessage)")
    }

    func testEvaluateNotesWithWhitespaceOnlyKeyTreatedAsEmpty() {
        let viewModel = NotesAssistantViewModel()
        viewModel.notes = [NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")]
        viewModel.apiKey = "   \t\n  "

        viewModel.evaluateNotes()

        XCTAssertFalse(viewModel.isEvaluating)
        XCTAssertTrue(viewModel.statusMessage.contains("API key"))
    }

    // MARK: - canEvaluate / canApply

    func testCanEvaluateFalseWithNoNotes() {
        let viewModel = NotesAssistantViewModel()
        viewModel.apiKey = "sk-test"
        XCTAssertFalse(viewModel.canEvaluate)
    }

    func testCanEvaluateFalseWithNoAPIKey() {
        let viewModel = NotesAssistantViewModel()
        viewModel.notes = [NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")]
        XCTAssertFalse(viewModel.canEvaluate)
    }

    func testCanEvaluateTrueWithNotesAndKey() {
        let viewModel = NotesAssistantViewModel()
        viewModel.notes = [NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")]
        viewModel.apiKey = "sk-test"
        XCTAssertTrue(viewModel.canEvaluate)
    }

    func testCanEvaluateFalseWhileEvaluating() {
        let viewModel = NotesAssistantViewModel()
        viewModel.notes = [NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")]
        viewModel.apiKey = "sk-test"
        viewModel.isEvaluating = true
        XCTAssertFalse(viewModel.canEvaluate)
    }

    func testCanApplyFalseWithNoSuggestions() {
        let viewModel = NotesAssistantViewModel()
        viewModel.notes = [NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")]
        // No evaluations set
        XCTAssertFalse(viewModel.canApply)
    }

    func testCanApplyTrueWhenSuggestionsExist() {
        let viewModel = NotesAssistantViewModel()
        let note = NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")
        viewModel.notes = [note]
        viewModel.evaluations = [
            "1": NoteEvaluation(isMeaningful: true, reason: "Useful", suggestedCategory: "Work")
        ]
        XCTAssertTrue(viewModel.canApply)
    }

    // MARK: - suggestedMoveCount

    func testSuggestedMoveCountIsZeroWithNoEvaluations() {
        let viewModel = NotesAssistantViewModel()
        viewModel.notes = [NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")]
        XCTAssertEqual(viewModel.suggestedMoveCount, 0)
    }

    func testSuggestedMoveCountExcludesSameFolder() {
        let viewModel = NotesAssistantViewModel()
        let note = NoteItem(id: "1", title: "Test", body: "Body", folder: "Work")
        viewModel.notes = [note]
        // Suggested folder is the same as current — should not count.
        viewModel.evaluations = [
            "1": NoteEvaluation(isMeaningful: true, reason: "Useful", suggestedCategory: "Work")
        ]
        XCTAssertEqual(viewModel.suggestedMoveCount, 0)
    }

    func testSuggestedMoveCountExcludesNilSuggestion() {
        let viewModel = NotesAssistantViewModel()
        let note = NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")
        viewModel.notes = [note]
        viewModel.evaluations = [
            "1": NoteEvaluation(isMeaningful: false, reason: "Empty", suggestedCategory: nil)
        ]
        XCTAssertEqual(viewModel.suggestedMoveCount, 0)
    }

    func testSuggestedMoveCountExcludesEmptySuggestion() {
        let viewModel = NotesAssistantViewModel()
        let note = NoteItem(id: "1", title: "Test", body: "Body", folder: "Inbox")
        viewModel.notes = [note]
        viewModel.evaluations = [
            "1": NoteEvaluation(isMeaningful: false, reason: "Junk", suggestedCategory: "  ")
        ]
        XCTAssertEqual(viewModel.suggestedMoveCount, 0)
    }

    func testSuggestedMoveCountCountsDifferentFolder() {
        let viewModel = NotesAssistantViewModel()
        let note1 = NoteItem(id: "1", title: "A", body: "", folder: "Inbox")
        let note2 = NoteItem(id: "2", title: "B", body: "", folder: "Inbox")
        let note3 = NoteItem(id: "3", title: "C", body: "", folder: "Work") // already in correct folder
        viewModel.notes = [note1, note2, note3]
        viewModel.evaluations = [
            "1": NoteEvaluation(isMeaningful: true, reason: "r", suggestedCategory: "Work"),
            "2": NoteEvaluation(isMeaningful: true, reason: "r", suggestedCategory: "Personal"),
            "3": NoteEvaluation(isMeaningful: true, reason: "r", suggestedCategory: "Work")
        ]
        XCTAssertEqual(viewModel.suggestedMoveCount, 2)
    }

    // MARK: - fetchNotes() guard

    func testFetchNotesGuardPreventsDoubleFetch() {
        let viewModel = NotesAssistantViewModel()
        viewModel.isFetching = true
        // A second call while already fetching should be a no-op.
        viewModel.fetchNotes()
        // isFetching should remain true and statusMessage should not change to "Fetching notes..."
        // (it was already true before the call, so the guard short-circuits).
        XCTAssertTrue(viewModel.isFetching,
                      "isFetching guard should prevent a second concurrent fetch")
        XCTAssertEqual(viewModel.statusMessage, "Fetch notes to begin",
                       "statusMessage should not be updated when the guard fires")
    }
}
