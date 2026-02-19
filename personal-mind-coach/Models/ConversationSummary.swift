//
//  ConversationSummary.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation
import SwiftData

@Model
final class ConversationSummary {
    @Attribute(.unique) var id: UUID
    var summaryText: String  // 대화 요약
    var startMessageId: UUID  // 요약 시작 메시지 ID
    var endMessageId: UUID  // 요약 종료 메시지 ID
    var messageIds: [UUID]  // 요약에 포함된 모든 메시지 ID
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        summaryText: String,
        startMessageId: UUID,
        endMessageId: UUID,
        messageIds: [UUID]
    ) {
        self.id = id
        self.summaryText = summaryText
        self.startMessageId = startMessageId
        self.endMessageId = endMessageId
        self.messageIds = messageIds
        self.createdAt = Date()
    }
}
