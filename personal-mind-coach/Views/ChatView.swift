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
    ) private var allMessages: [Message]
    
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @State private var selectedBranchMessageId: UUID? = nil
    @State private var showBranchInput = false
    @State private var showUndoToast = false
    
    // 현재 브랜치의 메시지만 필터링
    private var messages: [Message] {
        viewModel.getCurrentBranchMessages(from: allMessages)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                            GeometryReader { geo in
                                LazyVStack(spacing: 16) {
                                    if messages.isEmpty && !viewModel.isLoading {
                                    VStack(spacing: 12) {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                            .font(.system(size: 48))
                                            .foregroundColor(.gray.opacity(0.5))
                                        Text("안녕하세요! 마인드 코치입니다.")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        Text("무엇이든 편하게 이야기해주세요.")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 60)
                                }
                                
                                    ForEach(messages) { message in
                                        HStack {
                                            if message.messageRole == .user {
                                                Spacer()
                                            }
                                            CloudBubbleView(
                                                message: message,
                                                availableWidth: geo.size.width,
                                                onBranchTap: (message.messageRole == .model && viewModel.isOnMainBranch()) ? { messageId in
                                                    viewModel.enterBranchMode(from: messageId)
                                                    selectedBranchMessageId = messageId
                                                    showBranchInput = true
                                                } : nil,
                                                onDelete: { messageId in
                                                    withAnimation(.cloudDissolve) {
                                                        viewModel.deleteMessage(messageId)
                                                    }
                                                    showUndoToast = true
                                                }
                                            )
                                            if message.messageRole == .model {
                                                Spacer()
                                            }
                                        }
                                        .id(message.id)
                                        .transition(.opacity.combined(with: .scale))
                                    }
                                    
                                    if viewModel.isLoading {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("응답 중...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .accessibilityIdentifier("loadingIndicator")
                                    }
                                    .padding(.vertical, 8)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .accessibilityIdentifier("ChatView")
                        .onChange(of: messages.count) { _, _ in
                            if let lastMessage = messages.last {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) { _, isLoading in
                            if isLoading, let lastMessage = messages.last {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
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
                                    .accessibilityIdentifier("branchInputLabel")
                                Spacer()
                                Button("취소") {
                                    // 브랜치 모드 취소: 메인 브랜치로 복귀
                                    viewModel.returnToMainBranch()
                                    showBranchInput = false
                                    selectedBranchMessageId = nil
                                }
                                .font(.caption)
                                .accessibilityIdentifier("cancelBranchButton")
                            }
                            .padding(.horizontal)
                            
                            MessageInputBar(
                                text: $inputText,
                                isLoading: viewModel.isLoading,
                                onSend: { text in
                                    Task {
                                        if let parentId = selectedBranchMessageId {
                                            await viewModel.createBranch(from: parentId, question: text)
                                            // 브랜치 생성 후에도 브랜치 입력 모드 유지 (브랜치 뷰로 전환됨)
                                            // 하지만 입력 바는 일반 모드로 복귀
                                            inputText = ""
                                            showBranchInput = false
                                            selectedBranchMessageId = nil
                                        } else {
                                            await viewModel.sendMessage(text)
                                            inputText = ""
                                            showBranchInput = false
                                            selectedBranchMessageId = nil
                                        }
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
                
                // Undo Toast
                if showUndoToast {
                    VStack {
                        Spacer()
                        UndoToast {
                            viewModel.undoDelete()
                            showUndoToast = false
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("마인드 코치")
            .accessibilityIdentifier("ChatView")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if !os(macOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 설정 화면으로 이동 (나중에 구현)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("설정")
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        // 설정 화면으로 이동 (나중에 구현)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("설정")
                }
                #endif
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
            .alert("오류", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                } else {
                    Text("알 수 없는 오류가 발생했습니다.")
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .modelContainer(for: [Message.self, Session.self, Background.self, ConversationSummary.self])
}
