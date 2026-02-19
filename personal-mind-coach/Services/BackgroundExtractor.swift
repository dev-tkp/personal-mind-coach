//
//  BackgroundExtractor.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation

@MainActor
class BackgroundExtractor {
    private let apiService = GeminiAPIService()
    
    func extractBackground(
        from messages: [Message],
        previousBackground: Background?
    ) async throws -> String {
        let recentMessages = Array(messages.suffix(5))  // 최근 5턴
        
        let conversationText = recentMessages.map { message in
            "\(message.messageRole == .user ? "사용자" : "상담가"): \(message.content)"
        }.joined(separator: "\n\n")
        
        let previousBackgroundText = previousBackground?.summaryText ?? "없음"
        
        let prompt = """
다음 대화를 읽고, 사용자에 대한 중요한 정보(직업, 관계, 감정 상태, 주요 고민 등)를 요약해주세요. 
이전 백그라운드 정보와 병합하여 업데이트된 요약을 제공하세요.

이전 백그라운드: \(previousBackgroundText)

최근 대화:
\(conversationText)

요약 형식:
- 사용자의 주요 정보 (직업, 관계 등)
- 현재 감정 상태
- 주요 고민이나 이슈
- 중요한 맥락이나 배경

간결하고 구조화된 형식으로 작성해주세요.
"""
        
        let messageContent = MessageContent(role: "user", text: prompt)
        let systemPrompt = "당신은 대화를 분석하여 사용자에 대한 중요한 정보를 추출하는 전문가입니다."
        
        return try await apiService.generateContent(
            messages: [messageContent],
            systemInstruction: systemPrompt
        )
    }
}
