//
//  BranchIndicator.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI

struct BranchIndicator: View {
    let branchPath: [Message]
    let onReturnToMain: () -> Void
    
    var body: some View {
        if !branchPath.isEmpty {
            HStack {
                Button(action: onReturnToMain) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("메인으로 돌아가기")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("브랜치: \(branchPath.count)개 메시지")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
        }
    }
}

#Preview {
    BranchIndicator(branchPath: []) {
        print("Return to main")
    }
}
