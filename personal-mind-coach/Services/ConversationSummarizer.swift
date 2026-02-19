//
//  ConversationSummarizer.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation

@MainActor
class ConversationSummarizer {
    private let apiService = GeminiAPIService()
    
    func summarizeConversation(messages: [Message]) async throws -> String {
        let conversationText = messages.map { message in
            "\(message.messageRole == .user ? "사용자" : "상담가"): \(message.content)"
        }.joined(separator: "\n\n")
        
        let prompt = """
다음 대화를 간결하게 요약해주세요. 중요한 정보와 맥락을 유지하세요.

\(conversationText)

요약 형식:
- 주요 주제나 고민
- 중요한 정보나 맥락
- 감정 상태나 변화

간결하고 핵심적인 내용만 포함해주세요.
"""
        
        let messageContent = MessageContent(role: "user", text: prompt)
        let systemPrompt = "당신은 대화를 요약하는 전문가입니다. 중요한 정보와 맥락을 유지하면서 간결하게 요약하세요."
        
        return try await apiService.generateContent(
            messages: [messageContent],
            systemInstruction: systemPrompt
        )
    }
}
