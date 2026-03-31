//
//  ChatViewModel.swift
//  SpokenDialogue
//
//  Created by Kosuke Mori on 2026/03/31.
//

import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var text = ""
    @Published var messages: [Message] = []
    @Published var selectedModel: LLM = .gpt
    @Published private(set) var isRecording = false

    private let asrClient: ASRClient
    private let audioClient: AudioClient
    private let llmClient: LLMClient
    private let ttsClient: TTSClient
    
    init(
        asrClient: ASRClient? = nil,
        llmClient: LLMClient = LLMClient(),
        ttsClient: TTSClient = TTSClient()
    ) {
        let asrClient = asrClient ?? ASRClient()
        self.asrClient = asrClient
        self.audioClient = AudioClient(asrClient: asrClient)
        self.llmClient = llmClient
        self.ttsClient = ttsClient
    }
    
    func onAppear() {
        asrClient.requestAuthorization()
    }
    
    func onChange() {
        let trimmed = asrClient.finalTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        responses(text: trimmed)
        asrClient.clear()
    }
    
    func toggleRecording() {
        if isRecording {
            audioClient.stop()
            return
        }
        
        Task {
            try await audioClient.start()
        }
    }
    
    func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isRecording else { return }
        responses(text: trimmed)
    }
    
    private func responses(text: String) {
        let userMessage = Message(role: "user", content: text)
        messages.append(userMessage)
        self.text = ""
        
        let assistantID = UUID()
        var content = ""
        messages.append(Message(id: assistantID, role: "assistant", content: ""))
        
        Task {
            for try await event in llmClient.streamResponses(messages: messages, model: selectedModel) {
                switch event {
                case .delta(let delta):
                    guard let index = messages.firstIndex(where: { $0.id == assistantID }) else {
                        return
                    }
                    messages[index].content += delta
                    content += delta
                case .completed:
                    break
                }
            }
            
            if !content.isEmpty {
                try ttsClient.synthesize(text: content, rate: 0.5)
            }
        }
    }
}
