import Foundation

public struct NoteItem: Identifiable, Codable {
    public let id: String
    public let title: String
    public let body: String
    public let folder: String
}

public final class NotesService {
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
        
        let script = NSAppleScript(source: scriptSource)
        var error: NSDictionary?
        let resultDescriptor = script?.executeAndReturnError(&error)
        
        if let err = error {
            throw NSError(domain: "NotesService", code: 1, userInfo: [NSLocalizedDescriptionKey: "AppleScript error: \(err)"])
        }
        
        guard let descriptor = resultDescriptor else { return [] }
        
        var notes: [NoteItem] = []
        for i in 1...descriptor.numberOfItems {
            if let item = descriptor.atIndex(i) {
                let id = item.atIndex(1)?.stringValue ?? ""
                let title = item.atIndex(2)?.stringValue ?? ""
                let body = item.atIndex(3)?.stringValue ?? ""
                let folder = item.atIndex(4)?.stringValue ?? ""
                notes.append(NoteItem(id: id, title: title, body: body, folder: folder))
            }
        }
        return notes
    }
    
    public func moveNote(id: String, toFolder folderName: String) throws {
        let scriptSource = """
        tell application "Notes"
            if not (exists folder "\(folderName)") then
                make new folder with properties {name:"\(folderName)"}
            end if
            set theNote to note id "\(id)"
            set theFolder to folder "\(folderName)"
            move theNote to theFolder
        end tell
        """
        let script = NSAppleScript(source: scriptSource)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let err = error {
            throw NSError(domain: "NotesService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to move note: \(err)"])
        }
    }
    
    public func deleteNote(id: String) throws {
        let scriptSource = """
        tell application "Notes"
            delete note id "\(id)"
        end tell
        """
        let script = NSAppleScript(source: scriptSource)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let err = error {
            throw NSError(domain: "NotesService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to delete note: \(err)"])
        }
    }
}
