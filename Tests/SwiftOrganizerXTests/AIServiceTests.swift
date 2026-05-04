import XCTest
@testable import SwiftOrganizerX

/// Tests for the pure, non-networked surface area of AIService.
///
/// `AIService.evaluate(note:)` calls `URLSession.shared` directly with no injection
/// point, so it cannot be unit-tested without a live OpenAI key and network. The
/// testable surface covered here is:
///   - `AIService.defaultModel` static constant
///   - `NoteEvaluation` Codable conformance (the struct produced by `evaluate`)
final class AIServiceTests: XCTestCase {

    // MARK: - defaultModel

    func testDefaultModelIsGPT41Mini() {
        XCTAssertEqual(AIService.defaultModel, "gpt-4.1-mini")
    }

    // MARK: - NoteEvaluation Codable

    func testNoteEvaluationDecodesFromJSONWithSuggestedCategory() throws {
        let json = """
        {
            "is_meaningful": true,
            "reason": "Contains useful meeting notes.",
            "suggested_category": "Work"
        }
        """.data(using: .utf8)!

        let evaluation = try JSONDecoder().decode(NoteEvaluation.self, from: json)

        XCTAssertTrue(evaluation.isMeaningful)
        XCTAssertEqual(evaluation.reason, "Contains useful meeting notes.")
        XCTAssertEqual(evaluation.suggestedCategory, "Work")
    }

    func testNoteEvaluationDecodesFromJSONWithNullSuggestedCategory() throws {
        let json = """
        {
            "is_meaningful": false,
            "reason": "Note is empty.",
            "suggested_category": null
        }
        """.data(using: .utf8)!

        let evaluation = try JSONDecoder().decode(NoteEvaluation.self, from: json)

        XCTAssertFalse(evaluation.isMeaningful)
        XCTAssertEqual(evaluation.reason, "Note is empty.")
        XCTAssertNil(evaluation.suggestedCategory)
    }

    func testNoteEvaluationCodableRoundTripWithCategory() throws {
        let original = NoteEvaluation(isMeaningful: true, reason: "Useful note", suggestedCategory: "Personal")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteEvaluation.self, from: data)

        XCTAssertEqual(decoded.isMeaningful, original.isMeaningful)
        XCTAssertEqual(decoded.reason, original.reason)
        XCTAssertEqual(decoded.suggestedCategory, original.suggestedCategory)
    }

    func testNoteEvaluationCodableRoundTripWithNilCategory() throws {
        let original = NoteEvaluation(isMeaningful: false, reason: "Too short", suggestedCategory: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteEvaluation.self, from: data)

        XCTAssertEqual(decoded.isMeaningful, original.isMeaningful)
        XCTAssertEqual(decoded.reason, original.reason)
        XCTAssertNil(decoded.suggestedCategory)
    }
}
