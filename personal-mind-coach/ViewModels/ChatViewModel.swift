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
            AppLogger.general.debug("메시지 전송 시작: \(trimmedText.prefix(50))")
            
            // 사용자 메시지가 저장된 후 다시 메시지 가져오기
            // SwiftData의 변경사항이 반영되도록 약간의 지연
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
            
            let allMessages = getMessages()
            AppLogger.general.debug("전체 메시지 수: \(allMessages.count)")
            
            // 사용자 메시지가 포함되었는지 확인
            if let savedUserMessage = allMessages.first(where: { $0.id == userMessage.id }) {
                AppLogger.general.debug("✅ 사용자 메시지 확인됨: \(savedUserMessage.content.prefix(50))")
            } else {
                AppLogger.general.warning("⚠️ 사용자 메시지를 찾을 수 없음: \(userMessage.id)")
            }
            
            // 현재 브랜치 경로의 메시지들만 필터링
            var currentBranchMessages = getCurrentBranchMessages(from: allMessages)
            
            // 사용자 메시지가 포함되었는지 확인
            let userMessageIncluded = currentBranchMessages.contains(where: { $0.id == userMessage.id })
            if userMessageIncluded {
                AppLogger.general.debug("✅ 사용자 메시지가 브랜치 메시지에 포함됨")
            } else {
                AppLogger.general.warning("⚠️ 사용자 메시지가 브랜치 메시지에 포함되지 않음. 수동으로 추가합니다.")
                // 사용자 메시지를 수동으로 추가
                currentBranchMessages.append(userMessage)
                // 시간순 정렬
                currentBranchMessages.sort { $0.createdAt < $1.createdAt }
            }
            
            // 중복 제거 (같은 ID를 가진 메시지가 여러 번 포함되는 경우 방지)
            var seenIds = Set<UUID>()
            currentBranchMessages = currentBranchMessages.filter { message in
                if seenIds.contains(message.id) {
                    AppLogger.general.warning("⚠️ 중복 메시지 발견: \(message.id)")
                    return false
                }
                seenIds.insert(message.id)
                return true
            }
            
            AppLogger.general.debug("현재 브랜치 메시지 수: \(currentBranchMessages.count)")
            
            // 컨텍스트 최적화: 토큰 수가 임계치를 초과하면 요약 생성
            if ContextOptimizer.exceedsThreshold(messages: currentBranchMessages) {
                AppLogger.general.debug("컨텍스트 최적화 시작")
                currentBranchMessages = await optimizeContext(messages: currentBranchMessages)
            }
            
            // 메시지 순서 확인 및 로깅
            AppLogger.general.debug("📋 API 요청 전 메시지 확인:")
            for (index, msg) in currentBranchMessages.enumerated() {
                let role = msg.messageRole == .user ? "user" : "model"
                AppLogger.general.debug("  [\(index)] \(role): \(msg.content.prefix(50))")
            }
            
            let messageContents = buildMessageContents(from: currentBranchMessages)
            let latestBackground = getLatestBackground()
            let systemPrompt = SystemPrompt.buildPrompt(
                backgroundSummary: latestBackground?.summaryText
            )
            
            AppLogger.api.debug("API 호출 시작 - 메시지 수: \(messageContents.count)")
            
            let responseText = try await apiService.generateContent(
                messages: messageContents,
                systemInstruction: systemPrompt
            )
            
            // 빈 응답 체크
            let trimmedResponse = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedResponse.isEmpty else {
                AppLogger.general.warning("⚠️ API 응답이 비어있음")
                errorMessage = "응답을 받지 못했습니다. 다시 시도해주세요."
                isLoading = false
                return
            }
            
            AppLogger.general.debug("API 응답 수신 완료: \(trimmedResponse.prefix(50))")
            
            // AI 응답 저장 (사용자 메시지의 자식으로 설정)
            // 브랜치인 경우: parentId는 사용자 메시지의 ID
            // 메인인 경우: parentId는 nil
            let modelMessage = Message(role: .model, content: trimmedResponse, parentId: parentMessageId != nil ? userMessage.id : nil)
            modelContext.insert(modelMessage)
            
            // 세션 업데이트
            // 브랜치인 경우에만 세션의 currentMessageId를 브랜치의 루트로 설정
            // 메인 브랜치에서는 currentMessageId를 nil로 유지 (브랜치 뷰로 전환하지 않음)
            if let session = currentSession {
                if parentMessageId != nil {
                    // 브랜치 생성: 부모 메시지의 루트를 찾아서 설정
                    session.currentMessageId = findBranchRoot(from: parentMessageId!, in: modelContext) ?? modelMessage.id
                    session.updatedAt = Date()
                    AppLogger.general.debug("✅ 브랜치 모드: currentMessageId = \(session.currentMessageId?.uuidString ?? "nil")")
                } else {
                    // 메인 브랜치: currentMessageId를 nil로 유지 (또는 이미 nil이면 변경하지 않음)
                    // '여기서 더 물어보기' 버튼을 클릭하지 않았으므로 브랜치 뷰로 전환하지 않음
                    if session.currentMessageId != nil {
                        AppLogger.general.debug("⚠️ 메인 브랜치에서 currentMessageId가 nil이 아님. nil로 설정합니다.")
                        session.currentMessageId = nil
                        session.updatedAt = Date()
                    }
                    // 이미 nil이면 아무것도 하지 않음
                }
            }
            
            try modelContext.save()
            AppLogger.general.debug("✅ 메시지 DB 저장 완료 - User: \(userMessage.id), Model: \(modelMessage.id)")
            
            // 백그라운드 업데이트 (주기적으로)
            messageCountSinceLastBackgroundUpdate += 1
            if messageCountSinceLastBackgroundUpdate >= backgroundUpdateInterval {
                await updateBackground()
            }
        } catch {
            AppLogger.general.error("메시지 전송 실패: \(error.localizedDescription)")
            
            if let geminiError = error as? GeminiAPIError {
                errorMessage = geminiError.localizedDescription
                AppLogger.api.error("Gemini API 에러: \(geminiError.localizedDescription)")
            } else if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    errorMessage = "인터넷 연결을 확인해주세요."
                case .timedOut:
                    errorMessage = "요청 시간이 초과되었습니다. 다시 시도해주세요."
                default:
                    errorMessage = "네트워크 오류가 발생했습니다: \(urlError.localizedDescription)"
                }
                AppLogger.api.error("네트워크 에러: \(urlError.localizedDescription)")
            } else {
                errorMessage = "오류가 발생했습니다: \(error.localizedDescription)"
                AppLogger.general.error("알 수 없는 에러: \(error)")
            }
            // 사용자 메시지는 이미 저장되었으므로 그대로 둠
        }
        
        isLoading = false
    }
    
    /// 브랜치 모드로 진입 (버튼 클릭 시 즉시 브랜치 뷰로 전환)
    func enterBranchMode(from parentMessageId: UUID) {
        guard let modelContext = modelContext,
              let session = currentSession else { return }
        
        // parent message 확인
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.id == parentMessageId && !$0.isDeleted }
        )
        
        guard let parentMessage = try? modelContext.fetch(descriptor).first else {
            AppLogger.general.error("❌ Parent message를 찾을 수 없음: \(parentMessageId)")
            return
        }
        
        // parent message가 메인 브랜치에 있으면 parentMessageId를 브랜치 루트로 설정
        // 이미 브랜치에 있으면 해당 브랜치의 루트를 찾아서 설정
        let branchRoot: UUID?
        if parentMessage.parentId == nil {
            // 메인 브랜치의 메시지 → 새 브랜치 시작점
            branchRoot = parentMessageId
        } else {
            // 이미 브랜치 내부 → 브랜치 루트 찾기
            branchRoot = findBranchRoot(from: parentMessageId, in: modelContext)
        }
        
        // 브랜치 뷰로 전환: parent message를 포함한 브랜치 경로의 시작점 설정
        session.currentMessageId = branchRoot ?? parentMessageId
        session.updatedAt = Date()
        
        try? modelContext.save()
        AppLogger.general.debug("✅ 브랜치 모드 진입 - parentMessageId: \(parentMessageId), currentMessageId: \(session.currentMessageId?.uuidString ?? "nil"), branchRoot: \(branchRoot?.uuidString ?? "nil")")
    }
    
    /// 브랜치 질문 전송 및 브랜치 생성
    func createBranch(from parentMessageId: UUID, question: String) async {
        // 이미 브랜치 모드에 있으므로 바로 메시지 전송
        await sendMessage(question, parentMessageId: parentMessageId)
    }
    
    /// 브랜치의 루트 메시지 ID 찾기
    /// parent message가 메인 브랜치에 있으면 nil 반환 (메인 브랜치에서 시작하는 새 브랜치)
    /// 이미 브랜치 내부에 있으면 해당 브랜치의 루트 반환
    private func findBranchRoot(from messageId: UUID, in modelContext: ModelContext) -> UUID? {
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.id == messageId && !$0.isDeleted }
        )
        
        guard let message = try? modelContext.fetch(descriptor).first else {
            return nil
        }
        
        // parentId가 nil이면 메인 브랜치의 메시지 → 새 브랜치 시작점
        if message.parentId == nil {
            return nil  // 메인 브랜치에서 시작하는 새 브랜치
        }
        
        // 이미 브랜치 내부에 있으면, 브랜치의 루트를 찾아서 반환
        var currentId: UUID? = messageId
        
        while let id = currentId {
            let msgDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { $0.id == id && !$0.isDeleted }
            )
            
            guard let msg = try? modelContext.fetch(msgDescriptor).first else {
                break
            }
            
            // 부모가 메인 브랜치에 있으면 이 메시지가 브랜치의 루트
            if let parentId = msg.parentId {
                let parentDescriptor = FetchDescriptor<Message>(
                    predicate: #Predicate<Message> { $0.id == parentId && !$0.isDeleted }
                )
                if let parent = try? modelContext.fetch(parentDescriptor).first,
                   parent.parentId == nil {
                    return msg.id  // 이 메시지가 브랜치의 루트
                }
                currentId = parentId
            } else {
                break
            }
        }
        
        return currentId
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
            // 메인 브랜치: parentId가 nil인 메시지들만
            let mainMessages = allMessages.filter { $0.parentId == nil }
            AppLogger.general.debug("📋 getCurrentBranchMessages - 메인 브랜치, 메시지 수: \(mainMessages.count)")
            return mainMessages.sorted { $0.createdAt < $1.createdAt }
        }
        
        // currentMessageId가 nil이면 메인 브랜치
        guard let currentMessageId = session.currentMessageId else {
            let mainMessages = allMessages.filter { $0.parentId == nil }
            AppLogger.general.debug("📋 getCurrentBranchMessages - 메인 브랜치 (currentMessageId=nil), 메시지 수: \(mainMessages.count)")
            return mainMessages.sorted { $0.createdAt < $1.createdAt }
        }
        
        let branchMessages = BranchPathService.filterMessagesForCurrentBranch(
            allMessages: allMessages,
            currentMessageId: currentMessageId,
            in: modelContext
        )
        
        // 디버깅: 필터링 결과 확인
        AppLogger.general.debug("📋 getCurrentBranchMessages - currentMessageId: \(currentMessageId.uuidString)")
        AppLogger.general.debug("  전체 메시지 수: \(allMessages.count)")
        AppLogger.general.debug("  필터링된 메시지 수: \(branchMessages.count)")
        for (index, msg) in branchMessages.enumerated() {
            let role = msg.messageRole == .user ? "user" : "model"
            AppLogger.general.debug("  [\(index)] \(role): \(msg.content.prefix(30))")
        }
        
        return branchMessages
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
        let messageId = message.id
        let childrenDescriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { msg in
                msg.parentId == messageId && !msg.isDeleted
            }
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
        let messageId = message.id
        let childrenDescriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { msg in
                msg.parentId == messageId && msg.isDeleted
            }
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
        // 빈 메시지 필터링
        let validMessages = messages.filter { message in
            !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        let contents = validMessages.map { message in
            // role이 "user" 또는 "model"인지 확인
            let roleString: String
            switch message.messageRole {
            case .user:
                roleString = "user"
            case .model:
                roleString = "model"
            }
            
            return MessageContent(
                role: roleString,
                text: message.content
            )
        }
        
        // 디버깅: 메시지 내용 확인
        AppLogger.api.debug("📋 buildMessageContents - 메시지 개수: \(contents.count) (필터링 전: \(messages.count))")
        for (index, content) in contents.enumerated() {
            let preview = content.text.prefix(50)
            AppLogger.api.debug("  [\(index)] role=\(content.role), text=\(preview)\(content.text.count > 50 ? "..." : "")")
        }
        
        return contents
    }
}
