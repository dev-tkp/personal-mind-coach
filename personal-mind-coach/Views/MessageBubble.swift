//
//  MessageBubble.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MessageBubble: View {
    let message: Message
    var onBranchTap: ((UUID) -> Void)? = nil
    var onDelete: ((UUID) -> Void)? = nil
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack {
            if message.messageRole == .user {
                Spacer()
            }
            
            VStack(alignment: message.messageRole == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        message.messageRole == .user
                            ? Color.blue
                            : {
                                #if canImport(UIKit)
                                return Color(UIColor.systemGray5)
                                #else
                                return Color.gray.opacity(0.2)
                                #endif
                            }()
                    )
                    .foregroundColor(
                        message.messageRole == .user
                            ? .white
                            : .primary
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .onLongPressGesture {
                        showDeleteConfirmation = true
                    }
                    .accessibilityLabel(message.messageRole == .user ? "사용자 메시지" : "상담가 응답")
                    .accessibilityIdentifier(message.messageRole == .user ? "userMessage" : "modelMessage")
                    .accessibilityHint("길게 눌러 삭제할 수 있습니다")
                
                if message.messageRole == .model, let onBranchTap = onBranchTap {
                    BranchButton(messageId: message.id, onTap: {
                        onBranchTap(message.id)
                    })
                    .padding(.top, 4)
                }
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.messageRole == .model {
                Spacer()
            }
        }
        .confirmationDialog(
            "메시지 삭제",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                onDelete?(message.id)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 메시지와 하위 브랜치를 모두 삭제하시겠습니까?")
        }
    }
}

#Preview {
    VStack {
        MessageBubble(message: Message(role: .user, content: "안녕하세요"))
        MessageBubble(message: Message(role: .model, content: "안녕하세요! 무엇을 도와드릴까요?"))
    }
    .padding()
}
