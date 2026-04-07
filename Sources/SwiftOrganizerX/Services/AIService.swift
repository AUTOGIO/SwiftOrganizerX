import Foundation

public struct NoteEvaluation: Codable {
    public let isMeaningful: Bool
    public let reason: String
    public let suggestedCategory: String?
    
    enum CodingKeys: String, CodingKey {
        case isMeaningful = "is_meaningful"
        case reason
        case suggestedCategory = "suggested_category"
    }
}

public final class AIService {
    private let apiKey: String
    private let model: String
    
    public static let defaultModel = "gpt-4.1-mini"
    
    public init(apiKey: String, model: String = AIService.defaultModel) {
        self.apiKey = apiKey
        self.model = model
    }
    
    public func evaluate(note: NoteItem) async throws -> NoteEvaluation {
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "instructions": "You evaluate Apple Notes for organization. Return only the requested JSON. Mark short, duplicate, or low-signal notes as not meaningful. Suggested categories must be concise folder names suitable for Apple Notes.",
            "input": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "input_text",
                            "text": """
                            Evaluate this Apple Note for organization.
                            Title: \(note.title)
                            Current folder: \(note.folder)
                            Content:
                            \(note.body)
                            """
                        ]
                    ]
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "note_evaluation",
                    "strict": true,
                    "schema": [
                        "type": "object",
                        "properties": [
                            "is_meaningful": ["type": "boolean"],
                            "reason": ["type": "string"],
                            "suggested_category": [
                                "type": ["string", "null"]
                            ]
                        ],
                        "required": ["is_meaningful", "reason", "suggested_category"],
                        "additionalProperties": false
                    ]
                ]
            ],
            "max_output_tokens": 200
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse("The API did not return an HTTP response.")
        }
        
        let decoder = JSONDecoder()
        if !(200..<300).contains(httpResponse.statusCode) {
            let apiError = try? decoder.decode(OpenAIErrorEnvelope.self, from: data)
            let message = apiError?.error.message ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw AIServiceError.api(message)
        }
        
        let apiResponse = try decoder.decode(ResponsesAPIResponse.self, from: data)
        if let errorMessage = apiResponse.error?.message {
            throw AIServiceError.api(errorMessage)
        }
        if let incompleteReason = apiResponse.incompleteDetails?.reason {
            throw AIServiceError.invalidResponse("Response incomplete: \(incompleteReason).")
        }
        
        guard let content = apiResponse.outputText ?? apiResponse.firstTextContent,
              let jsonData = content.data(using: .utf8) else {
            throw AIServiceError.invalidResponse("The model did not return structured output.")
        }
        
        return try decoder.decode(NoteEvaluation.self, from: jsonData)
    }
    
    private struct ResponsesAPIResponse: Codable {
        struct OutputItem: Codable {
            struct ContentItem: Codable {
                let type: String?
                let text: String?
            }
            
            let content: [ContentItem]?
        }
        
        struct IncompleteDetails: Codable {
            let reason: String
            
            enum CodingKeys: String, CodingKey {
                case reason
            }
        }
        
        struct APIError: Codable {
            let message: String
        }
        
        let output: [OutputItem]
        let outputText: String?
        let error: APIError?
        let incompleteDetails: IncompleteDetails?
        
        enum CodingKeys: String, CodingKey {
            case output
            case outputText = "output_text"
            case error
            case incompleteDetails = "incomplete_details"
        }
        
        var firstTextContent: String? {
            for item in output {
                guard let content = item.content else { continue }
                if let text = content.first(where: { $0.type == "output_text" || $0.type == "text" })?.text {
                    return text
                }
            }
            return nil
        }
    }
    
    private struct OpenAIErrorEnvelope: Codable {
        struct APIError: Codable {
            let message: String
        }
        
        let error: APIError
    }
    
    private enum AIServiceError: LocalizedError {
        case api(String)
        case invalidResponse(String)
        
        var errorDescription: String? {
            switch self {
            case .api(let message), .invalidResponse(let message):
                return message
            }
        }
    }
}
