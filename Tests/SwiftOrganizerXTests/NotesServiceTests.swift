import XCTest
@testable import SwiftOrganizerX

final class NotesServiceTests: XCTestCase {

    // MARK: - Tests
    // NotesService.stripHTML is internal and accessible via @testable import.

    func testStripHTMLRemovesBasicTags() {
        XCTAssertEqual(NotesService.stripHTML("<b>hello</b>"), "hello")
    }

    func testStripHTMLRemovesDivAndSpan() {
        let html = "<div><span>Hello</span> <span>World</span></div>"
        XCTAssertEqual(NotesService.stripHTML(html), "Hello World")
    }

    func testStripHTMLRemovesScriptBlockAndContent() {
        let html = "before<script type=\"text/javascript\">alert('xss')</script>after"
        XCTAssertEqual(NotesService.stripHTML(html), "before after")
    }

    func testStripHTMLRemovesMultilineScriptBlock() {
        let html = "text<script>\nvar x = 1;\nvar y = 2;\n</script>more"
        XCTAssertEqual(NotesService.stripHTML(html), "text more")
    }

    func testStripHTMLRemovesStyleBlockAndContent() {
        let html = "text<style>body { color: red; }</style>more"
        XCTAssertEqual(NotesService.stripHTML(html), "text more")
    }

    func testStripHTMLDecodesAmpersand() {
        XCTAssertEqual(NotesService.stripHTML("cats &amp; dogs"), "cats & dogs")
    }

    func testStripHTMLDecodesAllEntities() {
        XCTAssertEqual(NotesService.stripHTML("&lt;b&gt;&quot;hi&quot;&nbsp;&#39;"), "<b>\"hi\" '")
    }

    func testStripHTMLEmptyString() {
        XCTAssertEqual(NotesService.stripHTML(""), "")
    }

    func testStripHTMLPlainTextUnchanged() {
        XCTAssertEqual(NotesService.stripHTML("Hello, world!"), "Hello, world!")
    }

    func testStripHTMLCollapsesExcessiveWhitespace() {
        XCTAssertEqual(NotesService.stripHTML("one   \n\n   two"), "one two")
    }

    // MARK: - NoteItem Codable
    // fetchAllNotes() and moveNote(id:toFolder:) call NSAppleScript directly with no
    // injection point; they cannot be unit-tested without refactoring NotesService to
    // accept a script-executor dependency. The Codable conformance of NoteItem — the
    // value type they produce and consume — is verified here instead.

    func testNoteItemCodableRoundTrip() throws {
        let original = NoteItem(id: "x-coredata://123", title: "Meeting", body: "Discuss roadmap", folder: "Work")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NoteItem.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.body, original.body)
        XCTAssertEqual(decoded.folder, original.folder)
    }

    // MARK: - stripHTML

    func testStripHTMLNoteShapedContent() {
        // Typical Apple Notes HTML structure
        let html = """
        <html><head><style>body{}</style></head>
        <body>
        <div><b>Meeting notes</b></div>
        <div>- Action item 1</div>
        <div>- Action item 2</div>
        <div><br></div>
        <div>Follow up with &lt;team&gt;</div>
        </body></html>
        """
        let result = NotesService.stripHTML(html)
        XCTAssertTrue(result.contains("Meeting notes"), "Title should survive stripping")
        XCTAssertTrue(result.contains("Action item 1"), "List items should survive")
        XCTAssertTrue(result.contains("<team>"), "Decoded entities should appear as literal text")
        XCTAssertFalse(result.contains("<b>"), "Bold tag should be stripped")
        XCTAssertFalse(result.contains("<div>"), "Div tags should be stripped")
        XCTAssertFalse(result.contains("<html>"), "Html tags should be stripped")
        XCTAssertFalse(result.contains("body{}"), "Style block content should be removed")
    }
}

