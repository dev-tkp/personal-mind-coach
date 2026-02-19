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
        
        // 브랜치 경로에 포함된 메시지 + 해당 브랜치의 모든 하위 메시지들 포함
        var branchMessages: [Message] = []
        for message in allMessages {
            // 브랜치 경로에 직접 포함된 메시지
            if branchPathIds.contains(message.id) {
                branchMessages.append(message)
            } else if let parentId = message.parentId {
                // 부모가 브랜치 경로에 포함되어 있으면 하위 메시지로 포함
                if branchPathIds.contains(parentId) || isDescendantOfBranch(messageId: message.id, branchPathIds: branchPathIds, allMessages: allMessages) {
                    branchMessages.append(message)
                }
            }
        }
        
        // 시간순으로 정렬
        return branchMessages.sorted { $0.createdAt < $1.createdAt }
    }
    
    /// 메시지가 브랜치 경로의 하위 메시지인지 확인
    private static func isDescendantOfBranch(messageId: UUID, branchPathIds: Set<UUID>, allMessages: [Message]) -> Bool {
        guard let message = allMessages.first(where: { $0.id == messageId }),
              let parentId = message.parentId else {
            return false
        }
        
        if branchPathIds.contains(parentId) {
            return true
        }
        
        // 재귀적으로 부모를 확인
        return isDescendantOfBranch(messageId: parentId, branchPathIds: branchPathIds, allMessages: allMessages)
    }
}
