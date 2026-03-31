//
//  ContentView.swift
//  SpokenDialogue
//
//  Created by Kosuke Mori on 2026/03/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                
                Text("SpokenDialogue")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(LLM.allCases) { model in
                            Text(model.rawValue).tag(model)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.selectedModel.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            
            Spacer()
            
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type message...", text: $viewModel.text, axis: .vertical)
                    .lineLimit(1...4)
                    .disabled(viewModel.isRecording)
                
                Button {
                    viewModel.toggleRecording()
                } label: {
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(Color.blue)
                        )
                }
                
                Button {
                    viewModel.send()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(viewModel.isRecording ? Color.gray :  Color.blue)
                        )
                }
                .disabled(viewModel.isRecording)
            }
            .padding()
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}


#Preview {
    ContentView()
}
