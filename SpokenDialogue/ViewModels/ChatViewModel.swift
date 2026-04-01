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

    private let asrService: ASRService
    private let audioService: AudioService
    private let llmService: LLMService
    private let ttsService: TTSService
    
    private var cancellables = Set<AnyCancellable>()
    private var liveUserMessageID: UUID?
    
    init(
        asrService: ASRService? = nil,
        llmService: LLMService = LLMService(),
        ttsService: TTSService = TTSService()
    ) {
        let asrService = asrService ?? ASRService()
        self.asrService = asrService
        self.audioService = AudioService(asrService: asrService)
        self.llmService = llmService
        self.ttsService = ttsService
        
        bindAudio()
        bindTranscript()
        bindFinalTranscript()
    }
    
    func onAppear() {
        asrService.requestAuthorization()
    }
    
    private func bindTranscript() {
        asrService.$transcript
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] text in
                self?.upsertLiveUserMessage(text)
            }
            .store(in: &cancellables)
    }
    
    private func bindAudio() {
        audioService.$isRecording
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)
    }
    
    private func bindFinalTranscript() {
        asrService.$finalTranscript
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .sink { [weak self] text in
                self?.finalizeUtteranceAndRespond(text)
            }
            .store(in: &cancellables)
    }
    
    private func upsertLiveUserMessage(_ text: String) {
        if let id = liveUserMessageID,
           let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].content = text
            return
        }
        
        let id = UUID()
        liveUserMessageID = id
        messages.append(Message(id: id, role: "user", content: text))
    }
    
    private func finalizeUtteranceAndRespond(_ finalText: String) {
        guard let id = liveUserMessageID,
              let index = messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        messages[index].content = finalText
                
        liveUserMessageID = nil
        asrService.clear()
        
        responses(requestMessages: messages)
    }
    
    func toggleRecording() {
        if isRecording {
            audioService.stop()
            return
        }
        
        Task {
            try await audioService.start()
        }
    }

    func startNewChat() {
        if isRecording {
            audioService.stop()
        }

        text = ""
        messages = []
        liveUserMessageID = nil
        asrService.clear()
    }
    
    func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isRecording else { return }
        
        let userMessage = Message(role: "user", content: text)
        messages.append(userMessage)
        text = ""

        responses(requestMessages: messages)
    }
    
    private func responses(requestMessages: [Message]) {
                
        let assistantID = UUID()
        var content = ""
        messages.append(Message(id: assistantID, role: "assistant", content: ""))
        
        Task {
            for try await event in llmService.streamResponses(messages: requestMessages, model: selectedModel) {
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
                try ttsService.synthesize(text: content, rate: 0.5)
            }
        }
    }
}
