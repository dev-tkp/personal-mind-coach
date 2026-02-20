//
//  BranchButton.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI

struct BranchButton: View {
    let messageId: UUID
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption)
                Text("여기서 더 물어보기")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .accessibilityLabel("여기서 더 물어보기")
        .accessibilityIdentifier("branchButton")
        .accessibilityHint("이 답변에 대해 추가 질문을 할 수 있습니다")
    }
}

#Preview {
    BranchButton(messageId: UUID()) {
        print("Branch tapped")
    }
}
