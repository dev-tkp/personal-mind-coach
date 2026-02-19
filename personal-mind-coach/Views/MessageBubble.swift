//
//  MessageBubble.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.messageRole == .user {
                Spacer()
            }
            
            VStack(alignment: message.messageRole == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        message.messageRole == .user
                            ? Color.blue
                            : Color.gray.opacity(0.2)
                    )
                    .foregroundColor(
                        message.messageRole == .user
                            ? .white
                            : .primary
                    )
                    .cornerRadius(16)
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.messageRole == .model {
                Spacer()
            }
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
