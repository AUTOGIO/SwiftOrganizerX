import XCTest
@testable import SwiftOrganizerX

final class FileCategoryTests: XCTestCase {

    func testCategoryForImageExtension() {
        XCTAssertEqual(FileCategory.category(for: ".png"), .images)
    }

    func testCategoryForDocumentExtension() {
        XCTAssertEqual(FileCategory.category(for: ".pdf"), .documents)
    }

    func testCategoryForUnknownExtension() {
        XCTAssertEqual(FileCategory.category(for: ".xyz"), .other)
    }
}
