//
//  ChatView.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Message> { !$0.isDeleted },
        sort: \Message.createdAt,
        order: .forward
    ) private var messages: [Message]
    
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @State private var selectedBranchMessageId: UUID? = nil
    @State private var showBranchInput = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 브랜치 인디케이터
                if !viewModel.isOnMainBranch() {
                    BranchIndicator(
                        branchPath: viewModel.getCurrentBranchPath(),
                        onReturnToMain: {
                            viewModel.returnToMainBranch()
                        }
                    )
                }
                
                // 메시지 리스트
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    onBranchTap: message.messageRole == .model ? { messageId in
                                        selectedBranchMessageId = messageId
                                        showBranchInput = true
                                    } : nil
                                )
                                .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .padding()
                                    Text("응답 중...")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 입력 바
                if showBranchInput {
                    VStack(spacing: 8) {
                        HStack {
                            Text("브랜치 질문:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("취소") {
                                showBranchInput = false
                                selectedBranchMessageId = nil
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        
                        MessageInputBar(
                            text: $inputText,
                            isLoading: viewModel.isLoading,
                            onSend: { text in
                                Task {
                                    if let parentId = selectedBranchMessageId {
                                        await viewModel.createBranch(from: parentId, question: text)
                                    } else {
                                        await viewModel.sendMessage(text)
                                    }
                                    inputText = ""
                                    showBranchInput = false
                                    selectedBranchMessageId = nil
                                }
                            }
                        )
                    }
                } else {
                    MessageInputBar(
                        text: $inputText,
                        isLoading: viewModel.isLoading,
                        onSend: { text in
                            Task {
                                await viewModel.sendMessage(text)
                                inputText = ""
                            }
                        }
                    )
                }
            }
            .navigationTitle("마인드 코치")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("설정") {
                        // 설정 화면으로 이동 (나중에 구현)
                    }
                }
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .modelContainer(for: [Message.self, Session.self, Background.self, ConversationSummary.self])
}
