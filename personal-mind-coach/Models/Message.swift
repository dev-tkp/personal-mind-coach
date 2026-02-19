//
//  Message.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var role: String  // "user" or "model"
    var content: String
    var parentId: UUID?  // 브랜치 부모 메시지 ID (nullable)
    var createdAt: Date
    var isDeleted: Bool  // 삭제 표시 (soft delete)
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        parentId: UUID? = nil
    ) {
        self.id = id
        self.role = role.rawValue
        self.content = content
        self.parentId = parentId
        self.createdAt = Date()
        self.isDeleted = false
    }
    
    var messageRole: MessageRole {
        get {
            MessageRole(rawValue: role) ?? .user
        }
        set {
            role = newValue.rawValue
        }
    }
}

enum MessageRole: String, Codable {
    case user
    case model
}
