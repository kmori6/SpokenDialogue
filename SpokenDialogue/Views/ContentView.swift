//
//  ContentView.swift
//  SpokenDialogue
//
//  Created by Kosuke Mori on 2026/03/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .detail

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            List {
                Button {
                    viewModel.startNewChat()
                    withAnimation {
                        preferredCompactColumn = .detail
                        columnVisibility = .detailOnly
                    }
                } label: {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        } detail: {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        withAnimation {
                            preferredCompactColumn = .sidebar
                            columnVisibility = .all
                        }
                    } label: {
                        Image(systemName: "sidebar.leading")
                            .imageScale(.large)
                    }
                    
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
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.secondarySystemBackground))
                
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
            .navigationBarBackButtonHidden(true)
            .onAppear {
                viewModel.onAppear()
            }
        }
    }
}


#Preview {
    ContentView()
}
