//
//  ContentView.swift
//  SpokenDialogue
//
//  Created by Kosuke Mori on 2026/03/27.
//

import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

struct ContentView: View {
    @State private var text: String = ""
    @State private var messages: [Message] = []
    @State private var isRecording = false
    
    private let llmClient = LLMClient()
    private let ttsClient = TTSClient()

    var body: some View {
        VStack(spacing: 0) {
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            
            Spacer()
            
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type message...", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                
                Button(action: {
                    if isRecording {
                        isRecording = false
                    } else {
                        isRecording = true
                    }
                }) {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(Color.blue)
                        )
                }
                
                Button(action: {
                    if !text.isEmpty {
                        send(text: text)
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(isRecording ? Color.gray :  Color.blue)
                        )
                }
                .disabled(isRecording)
            }
            .padding()
        }
    }
    
    private func send(text: String) {
        let message = Message(role: "user", content: text)
        messages.append(message)
        self.text = ""
        
        Task {
            let output = try await llmClient.responses(messages: messages)
            messages.append(output)
            try ttsClient.synthesize(text: output.content, rate: 0.5)
        }
    }
}

struct MessageView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer(minLength: 40)
                                
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                Spacer(minLength: 40)
            }
        }
    }
}

#Preview {
    ContentView()
}
