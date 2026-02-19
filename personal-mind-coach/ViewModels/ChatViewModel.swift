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
    private var modelContext: ModelContext?
    
    var currentSession: Session?
    var isLoading = false
    var errorMessage: String?
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
            print("백그라운드 업데이트 실패: \(error.localizedDescription)")
            // 백그라운드 업데이트 실패는 치명적이지 않으므로 계속 진행
        }
    }
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let modelContext = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        // 사용자 메시지 저장
        let userMessage = Message(role: .user, content: text)
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
            let messageContents = buildMessageContents(from: allMessages)
            let latestBackground = getLatestBackground()
            let systemPrompt = SystemPrompt.buildPrompt(
                backgroundSummary: latestBackground?.summaryText
            )
            
            let responseText = try await apiService.generateContent(
                messages: messageContents,
                systemInstruction: systemPrompt
            )
            
            // AI 응답 저장
            let modelMessage = Message(role: .model, content: responseText)
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
            errorMessage = error.localizedDescription
            // 사용자 메시지는 이미 저장되었으므로 그대로 둠
        }
        
        isLoading = false
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
