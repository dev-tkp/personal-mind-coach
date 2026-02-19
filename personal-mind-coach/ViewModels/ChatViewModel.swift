//
//  ChatViewModel.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class ChatViewModel {
    private let apiService = GeminiAPIService()
    private let backgroundExtractor = BackgroundExtractor()
    private let conversationSummarizer = ConversationSummarizer()
    private var modelContext: ModelContext?
    
    var currentSession: Session?
    var isLoading = false
    var errorMessage: String?
    var deletedMessageId: UUID?  // Undo용
    private var messageCountSinceLastBackgroundUpdate = 0
    private let backgroundUpdateInterval = 5  // 5턴마다 백그라운드 업데이트
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSession()
    }
    
    private func loadSession() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Session>()
        if let session = try? modelContext.fetch(descriptor).first {
            currentSession = session
        } else {
            // 새 세션 생성
            let newSession = Session()
            modelContext.insert(newSession)
            currentSession = newSession
            try? modelContext.save()
        }
    }
    
    func getMessages() -> [Message] {
        guard let modelContext = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { !$0.isDeleted },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func getLatestBackground() -> Background? {
        guard let modelContext = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<Background>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        return try? modelContext.fetch(descriptor).first
    }
    
    private func updateBackground() async {
        guard let modelContext = modelContext else { return }
        
        let messages = getMessages()
        guard !messages.isEmpty else { return }
        
        let previousBackground = getLatestBackground()
        
        do {
            let summaryText = try await backgroundExtractor.extractBackground(
                from: messages,
                previousBackground: previousBackground
            )
            
            let sourceMessageIds = messages.map { $0.id }
            let newVersion = (previousBackground?.version ?? 0) + 1
            
            let newBackground = Background(
                summaryText: summaryText,
                sourceMessageIds: sourceMessageIds
            )
            newBackground.version = newVersion
            
            modelContext.insert(newBackground)
            try modelContext.save()
            
            messageCountSinceLastBackgroundUpdate = 0
        } catch {
            AppLogger.background.error("백그라운드 업데이트 실패: \(error.localizedDescription)")
            // 백그라운드 업데이트 실패는 치명적이지 않으므로 계속 진행
        }
    }
    
    func sendMessage(_ text: String, parentMessageId: UUID? = nil) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            errorMessage = "메시지를 입력해주세요."
            return
        }
        
        guard let modelContext = modelContext else {
            errorMessage = "데이터베이스 연결 오류가 발생했습니다."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 사용자 메시지 저장 (브랜치인 경우 parentId 설정)
        let userMessage = Message(role: .user, content: trimmedText, parentId: parentMessageId)
        modelContext.insert(userMessage)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "메시지 저장 실패: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        // AI 응답 생성
        do {
            let allMessages = getMessages()
            // 현재 브랜치 경로의 메시지들만 필터링
            var currentBranchMessages = getCurrentBranchMessages(from: allMessages)
            
            // 컨텍스트 최적화: 토큰 수가 임계치를 초과하면 요약 생성
            if ContextOptimizer.exceedsThreshold(messages: currentBranchMessages) {
                currentBranchMessages = await optimizeContext(messages: currentBranchMessages)
            }
            
            let messageContents = buildMessageContents(from: currentBranchMessages)
            let latestBackground = getLatestBackground()
            let systemPrompt = SystemPrompt.buildPrompt(
                backgroundSummary: latestBackground?.summaryText
            )
            
            let responseText = try await apiService.generateContent(
                messages: messageContents,
                systemInstruction: systemPrompt
            )
            
            // AI 응답 저장 (사용자 메시지의 자식으로 설정)
            // 브랜치인 경우: parentId는 사용자 메시지의 ID
            // 메인인 경우: parentId는 nil
            let modelMessage = Message(role: .model, content: responseText, parentId: parentMessageId != nil ? userMessage.id : nil)
            modelContext.insert(modelMessage)
            
            // 세션 업데이트
            if let session = currentSession {
                session.currentMessageId = modelMessage.id
                session.updatedAt = Date()
            }
            
            try modelContext.save()
            
            // 백그라운드 업데이트 (주기적으로)
            messageCountSinceLastBackgroundUpdate += 1
            if messageCountSinceLastBackgroundUpdate >= backgroundUpdateInterval {
                await updateBackground()
            }
        } catch {
            if let geminiError = error as? GeminiAPIError {
                errorMessage = geminiError.localizedDescription
            } else if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    errorMessage = "인터넷 연결을 확인해주세요."
                case .timedOut:
                    errorMessage = "요청 시간이 초과되었습니다. 다시 시도해주세요."
                default:
                    errorMessage = "네트워크 오류가 발생했습니다: \(urlError.localizedDescription)"
                }
            } else {
                errorMessage = error.localizedDescription
            }
            // 사용자 메시지는 이미 저장되었으므로 그대로 둠
        }
        
        isLoading = false
    }
    
    func createBranch(from parentMessageId: UUID, question: String) async {
        await sendMessage(question, parentMessageId: parentMessageId)
    }
    
    func returnToMainBranch() {
        guard let modelContext = modelContext,
              let session = currentSession else { return }
        
        session.currentMessageId = nil
        session.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    func getCurrentBranchPath() -> [Message] {
        guard let modelContext = modelContext,
              let session = currentSession else { return [] }
        
        return BranchPathService.getBranchPath(
            from: session.currentMessageId,
            in: modelContext
        )
    }
    
    func isOnMainBranch() -> Bool {
        return currentSession?.currentMessageId == nil
    }
    
    func getCurrentBranchMessages(from allMessages: [Message]) -> [Message] {
        guard let modelContext = modelContext,
              let session = currentSession else {
            return allMessages.filter { $0.parentId == nil }
        }
        
        return BranchPathService.filterMessagesForCurrentBranch(
            allMessages: allMessages,
            currentMessageId: session.currentMessageId,
            in: modelContext
        )
    }
    
    func deleteMessage(_ messageId: UUID) {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.id == messageId }
        )
        
        guard let message = try? modelContext.fetch(descriptor).first else { return }
        
        // 하위 브랜치 재귀적 삭제
        deleteMessageRecursively(message, in: modelContext)
        
        // 백그라운드 롤백
        rollbackBackground(for: messageId)
        
        deletedMessageId = messageId
        try? modelContext.save()
    }
    
    private func deleteMessageRecursively(_ message: Message, in modelContext: ModelContext) {
        message.isDeleted = true
        
        // 자식 메시지들도 삭제
        let childrenDescriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.parentId == message.id && !$0.isDeleted }
        )
        
        if let children = try? modelContext.fetch(childrenDescriptor) {
            for child in children {
                deleteMessageRecursively(child, in: modelContext)
            }
        }
    }
    
    func undoDelete() {
        guard let messageId = deletedMessageId,
              let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.id == messageId }
        )
        
        guard let message = try? modelContext.fetch(descriptor).first else { return }
        
        // 메시지와 하위 브랜치 모두 복원
        undoDeleteRecursively(message, in: modelContext)
        
        // 백그라운드 복원
        Task {
            await updateBackground()
        }
        
        deletedMessageId = nil
        try? modelContext.save()
    }
    
    private func undoDeleteRecursively(_ message: Message, in modelContext: ModelContext) {
        message.isDeleted = false
        
        // 자식 메시지들도 복원
        let childrenDescriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.parentId == message.id && $0.isDeleted }
        )
        
        if let children = try? modelContext.fetch(childrenDescriptor) {
            for child in children {
                undoDeleteRecursively(child, in: modelContext)
            }
        }
    }
    
    private func rollbackBackground(for deletedMessageId: UUID) {
        guard let modelContext = modelContext else { return }
        
        // 삭제된 메시지를 포함하는 백그라운드 찾기
        let descriptor = FetchDescriptor<Background>()
        guard let backgrounds = try? modelContext.fetch(descriptor) else { return }
        
        for background in backgrounds {
            if background.sourceMessageIds.contains(deletedMessageId) {
                // 해당 메시지를 제외한 새 백그라운드 생성
                let remainingMessages = getMessages().filter { message in
                    !background.sourceMessageIds.contains(message.id) || message.id == deletedMessageId
                }
                
                if !remainingMessages.isEmpty {
                    Task {
                        await updateBackgroundFromMessages(remainingMessages)
                    }
                }
                break
            }
        }
    }
    
    private func updateBackgroundFromMessages(_ messages: [Message]) async {
        guard let modelContext = modelContext else { return }
        
        let previousBackground = getLatestBackground()
        
        do {
            let summaryText = try await backgroundExtractor.extractBackground(
                from: messages,
                previousBackground: previousBackground
            )
            
            let sourceMessageIds = messages.map { $0.id }
            let newVersion = (previousBackground?.version ?? 0) + 1
            
            let newBackground = Background(
                summaryText: summaryText,
                sourceMessageIds: sourceMessageIds
            )
            newBackground.version = newVersion
            
            modelContext.insert(newBackground)
            try modelContext.save()
        } catch {
            AppLogger.background.error("백그라운드 롤백 실패: \(error.localizedDescription)")
        }
    }
    
    private func optimizeContext(messages: [Message]) async -> [Message] {
        guard let modelContext = modelContext else { return messages }
        
        let (recent, older) = ContextOptimizer.splitMessages(messages, keepRecent: 10)
        
        guard !older.isEmpty else { return messages }
        
        // 오래된 메시지들 요약
        do {
            let summaryText = try await conversationSummarizer.summarizeConversation(messages: older)
            
            // ConversationSummary 저장
            let startMessageId = older.first?.id ?? UUID()
            let endMessageId = older.last?.id ?? UUID()
            let messageIds = older.map { $0.id }
            
            let summary = ConversationSummary(
                summaryText: summaryText,
                startMessageId: startMessageId,
                endMessageId: endMessageId,
                messageIds: messageIds
            )
            
            modelContext.insert(summary)
            try modelContext.save()
            
            // 요약을 메시지로 변환하여 반환
            let summaryMessage = Message(
                role: .model,
                content: "[이전 대화 요약]\n\(summaryText)"
            )
            
            return [summaryMessage] + recent
        } catch {
            AppLogger.general.error("컨텍스트 최적화 실패: \(error.localizedDescription)")
            return messages
        }
    }
    
    private func buildMessageContents(from messages: [Message]) -> [MessageContent] {
        return messages.map { message in
            MessageContent(
                role: message.role,
                text: message.content
            )
        }
    }
}
