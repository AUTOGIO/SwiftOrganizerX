import XCTest
@testable import SwiftOrganizerX

final class FileCategoryTests: XCTestCase {

    // MARK: - Existing extensions

    func testCategoryForImageExtension() {
        XCTAssertEqual(FileCategory.category(for: ".png"), .images)
    }

    func testCategoryForDocumentExtension() {
        XCTAssertEqual(FileCategory.category(for: ".pdf"), .documents)
    }

    func testCategoryForUnknownExtension() {
        XCTAssertEqual(FileCategory.category(for: ".xyz"), .other)
    }

    // MARK: - New image formats

    func testHEICCategorizedAsImages() {
        XCTAssertEqual(FileCategory.category(for: ".heic"), .images)
    }

    func testHEIFCategorizedAsImages() {
        XCTAssertEqual(FileCategory.category(for: ".heif"), .images)
    }

    func testICOCategorizedAsImages() {
        XCTAssertEqual(FileCategory.category(for: ".ico"), .images)
    }

    // MARK: - New document formats

    func testNumbersCategorizedAsDocuments() {
        XCTAssertEqual(FileCategory.category(for: ".numbers"), .documents)
    }

    func testPagesCategorizedAsDocuments() {
        XCTAssertEqual(FileCategory.category(for: ".pages"), .documents)
    }

    func testKeynoteCategorizedAsDocuments() {
        XCTAssertEqual(FileCategory.category(for: ".keynote"), .documents)
    }

    func testCSVCategorizedAsDocuments() {
        XCTAssertEqual(FileCategory.category(for: ".csv"), .documents)
    }

    func testMarkdownCategorizedAsDocuments() {
        XCTAssertEqual(FileCategory.category(for: ".md"), .documents)
    }

    // MARK: - New script / source-code formats

    func testSwiftCategorizedAsScripts() {
        XCTAssertEqual(FileCategory.category(for: ".swift"), .scripts)
    }

    func testTypeScriptCategorizedAsScripts() {
        XCTAssertEqual(FileCategory.category(for: ".ts"), .scripts)
    }

    func testTSXCategorizedAsScripts() {
        XCTAssertEqual(FileCategory.category(for: ".tsx"), .scripts)
    }

    func testJSXCategorizedAsScripts() {
        XCTAssertEqual(FileCategory.category(for: ".jsx"), .scripts)
    }

    func testGoCategorizedAsScripts() {
        XCTAssertEqual(FileCategory.category(for: ".go"), .scripts)
    }

    func testRustCategorizedAsScripts() {
        XCTAssertEqual(FileCategory.category(for: ".rs"), .scripts)
    }

    func testKotlinCategorizedAsScripts() {
        XCTAssertEqual(FileCategory.category(for: ".kt"), .scripts)
    }

    func testRubyCategorizedAsScripts() {
        XCTAssertEqual(FileCategory.category(for: ".rb"), .scripts)
    }

    func testCSharpCategorizedAsScripts() {
        XCTAssertEqual(FileCategory.category(for: ".cs"), .scripts)
    }

    // MARK: - New audio formats

    func testAIFFCategorizedAsAudio() {
        XCTAssertEqual(FileCategory.category(for: ".aiff"), .audio)
    }

    func testOpusCategorizedAsAudio() {
        XCTAssertEqual(FileCategory.category(for: ".opus"), .audio)
    }

    // MARK: - New archive formats

    func testXZCategorizedAsArchives() {
        XCTAssertEqual(FileCategory.category(for: ".xz"), .archives)
    }

    func testISOCategorizedAsArchives() {
        XCTAssertEqual(FileCategory.category(for: ".iso"), .archives)
    }

    // MARK: - Case insensitivity

    func testExtensionMatchingIsCaseInsensitive() {
        XCTAssertEqual(FileCategory.category(for: ".SWIFT"), .scripts)
        XCTAssertEqual(FileCategory.category(for: ".HEIC"), .images)
        XCTAssertEqual(FileCategory.category(for: ".PDF"), .documents)
        XCTAssertEqual(FileCategory.category(for: ".MP4"), .videos)
        XCTAssertEqual(FileCategory.category(for: ".ZIP"), .archives)
    }
}
