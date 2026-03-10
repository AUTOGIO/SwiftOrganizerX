import Foundation

public struct NoteEvaluation: Codable {
    public let is_meaningful: Bool
    public let reason: String
    public let suggested_category: String?
}

public final class AIService {
    private let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func evaluate(note: NoteItem) async throws -> NoteEvaluation {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        Evaluate this note and respond with a JSON object:
        Title: \(note.title)
        Content: \(note.body)
        Respond with JSON only in this format:
        {
            "is_meaningful": true/false,
            "reason": "Brief reason for your decision",
            "suggested_category": "Category name if meaningful, null if not"
        }
        """
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that evaluates notes."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content,
              let jsonData = content.data(using: .utf8) else {
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid API response"])
        }
        
        return try JSONDecoder().decode(NoteEvaluation.self, from: jsonData)
    }
    
    private struct OpenAIResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }
}
