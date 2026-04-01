//
//  LLMService.swift
//  SpokenDialogue
//
//  Created by Kosuke Mori on 2026/03/27.
//

import Foundation

struct Request: Encodable {
    let model: String
    let instructions: String
    let input: [MessageItem]
}

struct MessageItem: Encodable {
    let role: String
    let content: String
}

struct Responses: Decodable {
    let id: String
    let output: [Output]
}

struct Output: Codable {
    let role: String
    let content: [ContentItem]
}

struct ContentItem: Codable {
    let type: String
    let text: String
}

enum StreamEvent {
    case delta(String)
    case completed
}

struct OutputTextDeltaEvent: Codable {
    let delta: String
}

struct StreamRequest: Encodable {
    let model: String
    let instructions: String
    let input: [MessageItem]
    let stream = true
}


final class LLMService {
    private let instructions = "You are a helpful assistant. Chat with user in Japanese."
    private let baseURL = "https://api.openai.com/v1"
    
    func responses(messages: [Message], model: LLM) async throws -> Message {
        
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") else {
            return Message(role: "assistant", content: "API KEY load failed.")
        }
 
        let url = URL(string: "\(baseURL)/responses")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var input: [MessageItem] = []
        for message in messages {
            let item = MessageItem(role: message.role, content: message.content)
            input.append(item)
        }
        let body = Request(model: model.rawValue, instructions: instructions, input: input)
        
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        let json = try decoder.decode(Responses.self, from: data)
        
        let output = Message(role: json.output[0].role, content: json.output[0].content[0].text)
        return output
    }

    func streamResponses(messages: [Message], model: LLM) -> AsyncStream<StreamEvent> {
        AsyncStream { continuation in
            Task {
                let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY")!
                let decoder = JSONDecoder()
                
                let url = URL(string: "\(baseURL)/responses")
                var request = URLRequest(url: url!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                
                let body = StreamRequest(
                    model: model.rawValue,
                    instructions: instructions,
                    input: messages.map {
                        MessageItem(role: $0.role, content: $0.content)
                    }
                )
                
                request.httpBody = try JSONEncoder().encode(body)
                let (bytes, _) = try await URLSession.shared.bytes(for: request)
                for try await line in bytes.lines {
                    // https://developers.openai.com/api/reference/resources/responses/methods/create
                    guard line.hasPrefix("data: ") else {
                        continue
                    }
                    if line.contains("\"type\":\"response.output_text.delta\"") {
                        let data = String(line.dropFirst(5))
                        let chunk = try decoder.decode(OutputTextDeltaEvent.self, from: Data(data.utf8))
                        continuation.yield(.delta(chunk.delta))
                    } else if line.contains("\"type\":\"response.completed\"") {
                        continuation.yield(.completed)
                    }
                }
                continuation.finish()
            }
        }
    }
}
