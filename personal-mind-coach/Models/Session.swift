//
//  Session.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var currentMessageId: UUID?  // 현재 보고 있는 메시지 ID (브랜치 경로의 끝)
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID()) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
