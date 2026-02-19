//
//  BranchPathService.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation
import SwiftData

class BranchPathService {
    /// 현재 메시지 ID에서 시작하여 root까지의 브랜치 경로를 계산
    static func getBranchPath(
        from messageId: UUID?,
        in modelContext: ModelContext
    ) -> [Message] {
        guard let messageId = messageId else { return [] }
        
        var path: [Message] = []
        var currentId: UUID? = messageId
        
        while let id = currentId {
            let descriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { $0.id == id && !$0.isDeleted }
            )
            
            guard let message = try? modelContext.fetch(descriptor).first else {
                break
            }
            
            path.append(message)
            currentId = message.parentId
        }
        
        return path.reversed()  // root부터 현재까지 순서로 반환
    }
    
    /// 특정 메시지의 모든 자식 메시지를 재귀적으로 가져옴
    static func getAllChildren(
        of messageId: UUID,
        in modelContext: ModelContext
    ) -> [Message] {
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { $0.parentId == messageId && !$0.isDeleted },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        guard let children = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        var allChildren = children
        for child in children {
            allChildren.append(contentsOf: getAllChildren(of: child.id, in: modelContext))
        }
        
        return allChildren
    }
    
    /// 현재 브랜치 경로의 메시지들만 필터링
    static func filterMessagesForCurrentBranch(
        allMessages: [Message],
        currentMessageId: UUID?,
        in modelContext: ModelContext
    ) -> [Message] {
        guard let currentMessageId = currentMessageId else {
            // 메인 브랜치: parentId가 nil인 메시지들만
            return allMessages.filter { $0.parentId == nil }
        }
        
        let branchPath = getBranchPath(from: currentMessageId, in: modelContext)
        let branchPathIds = Set(branchPath.map { $0.id })
        
        // 브랜치 경로에 포함된 메시지들만 반환
        return allMessages.filter { branchPathIds.contains($0.id) }
    }
}
