//
//  ContextOptimizer.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation

class ContextOptimizer {
    /// 대략적인 토큰 수 추정 (1 토큰 ≈ 4 문자)
    static func estimateTokenCount(text: String) -> Int {
        return text.count / 4
    }
    
    /// 메시지 리스트의 예상 토큰 수 계산
    static func estimateTokenCount(messages: [Message]) -> Int {
        let totalText = messages.map { $0.content }.joined(separator: " ")
        return estimateTokenCount(text: totalText)
    }
    
    /// 토큰 임계치 (800K 토큰의 80% = 640K 토큰)
    static let tokenThreshold = 640_000
    
    /// 컨텍스트가 임계치를 초과하는지 확인
    static func exceedsThreshold(messages: [Message]) -> Bool {
        return estimateTokenCount(messages: messages) > tokenThreshold
    }
    
    /// 메시지를 최근 N턴과 이전 턴으로 분리
    static func splitMessages(
        _ messages: [Message],
        keepRecent: Int = 10
    ) -> (recent: [Message], older: [Message]) {
        guard messages.count > keepRecent else {
            return (recent: messages, older: [])
        }
        
        let recent = Array(messages.suffix(keepRecent))
        let older = Array(messages.prefix(messages.count - keepRecent))
        
        return (recent: recent, older: older)
    }
}
