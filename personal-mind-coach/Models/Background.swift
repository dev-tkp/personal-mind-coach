//
//  Background.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation
import SwiftData

@Model
final class Background {
    @Attribute(.unique) var id: UUID
    var summaryText: String  // 사용자 백그라운드 요약
    var sourceMessageIds: [UUID]  // 이 요약이 반영한 메시지 ID들
    var updatedAt: Date
    var version: Int  // 버전 관리 (삭제 시 롤백용)
    
    init(
        id: UUID = UUID(),
        summaryText: String,
        sourceMessageIds: [UUID] = []
    ) {
        self.id = id
        self.summaryText = summaryText
        self.sourceMessageIds = sourceMessageIds
        self.updatedAt = Date()
        self.version = 1
    }
}
