import Foundation

public struct NoteItem: Identifiable, Codable {
    public let id: String
    public let title: String
    public let body: String
    public let folder: String
}

/// `NotesService` is safe to use from a `Task.detached` closure provided only one
/// concurrent task accesses it at a time (enforced by the `isFetching`/`isApplying`
/// guards in `NotesAssistantViewModel`). Marked `@unchecked Sendable` to satisfy the
/// Swift concurrency checker; the caller is responsible for the single-access invariant.
public final class NotesService: @unchecked Sendable {
    public init() {}
    
    public func fetchAllNotes() async throws -> [NoteItem] {
        let scriptSource = """
        tell application "Notes"
            set allNotes to {}
            repeat with theNote in notes
                set noteID to id of theNote
                set noteTitle to name of theNote
                set noteBody to body of theNote
                set noteContainer to name of container of theNote
                set end of allNotes to {id:noteID, title:noteTitle, body:noteBody, folder:noteContainer}
            end repeat
            return allNotes
        end tell
        """

        let resultDescriptor = try executeAppleScript(
            scriptSource,
            code: 1,
            failureReason: "AppleScript error"
        )
        
        guard let descriptor = resultDescriptor else { return [] }
        guard descriptor.numberOfItems > 0 else { return [] }
        
        var notes: [NoteItem] = []
        for i in 1...descriptor.numberOfItems {
            if let item = descriptor.atIndex(i) {
                let id = item.atIndex(1)?.stringValue ?? ""
                let title = item.atIndex(2)?.stringValue ?? ""
                let rawBody = item.atIndex(3)?.stringValue ?? ""
                let folder = item.atIndex(4)?.stringValue ?? ""
                // Apple Notes' AppleScript `body` property returns HTML; strip tags before
                // storing so downstream consumers (e.g. AI evaluation) receive plain text.
                let body = Self.stripHTML(rawBody)
                notes.append(NoteItem(id: id, title: title, body: body, folder: folder))
            }
        }
        return notes
    }
    
    public func moveNote(id: String, toFolder folderName: String) throws {
        let escapedFolderName = Self.appleScriptLiteral(folderName)
        let escapedID = Self.appleScriptLiteral(id)
        let scriptSource = """
        tell application "Notes"
            if not (exists folder \(escapedFolderName)) then
                make new folder with properties {name:\(escapedFolderName)}
            end if
            set theNote to note id \(escapedID)
            set theFolder to folder \(escapedFolderName)
            move theNote to theFolder
        end tell
        """
        _ = try executeAppleScript(
            scriptSource,
            code: 2,
            failureReason: "Failed to move note"
        )
    }
    
    public func deleteNote(id: String) throws {
        let escapedID = Self.appleScriptLiteral(id)
        let scriptSource = """
        tell application "Notes"
            delete note id \(escapedID)
        end tell
        """
        _ = try executeAppleScript(
            scriptSource,
            code: 3,
            failureReason: "Failed to delete note"
        )
    }
    
    private func executeAppleScript(_ source: String, code: Int, failureReason: String) throws -> NSAppleEventDescriptor? {
        let script = NSAppleScript(source: source)
        var error: NSDictionary?
        let descriptor = script?.executeAndReturnError(&error)
        if let err = error {
            throw NSError(domain: "NotesService", code: code, userInfo: [NSLocalizedDescriptionKey: "\(failureReason): \(err)"])
        }
        return descriptor
    }
    
    private static func appleScriptLiteral(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    /// Strips HTML tags and decodes common HTML entities, returning plain text.
    /// Used to convert the HTML body returned by Apple Notes' AppleScript interface.
    static func stripHTML(_ html: String) -> String {
        // Remove script and style blocks and their content first.
        var text = html
            .replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: " ", options: .regularExpression)
        // Strip remaining tags.
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&nbsp;", " ")
        ]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
