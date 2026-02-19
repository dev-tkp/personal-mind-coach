//
//  BranchIndicator.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BranchIndicator: View {
    let branchPath: [Message]
    let onReturnToMain: () -> Void
    
    var body: some View {
        if !branchPath.isEmpty {
            HStack {
                Button(action: onReturnToMain) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                        Text("메인으로 돌아가기")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
                .accessibilityLabel("메인으로 돌아가기")
                
                Spacer()
                
                Text("브랜치: \(branchPath.count)개 메시지")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            #if canImport(UIKit)
            .background(Color(UIColor.systemGray6))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor.separator)),
                alignment: .bottom
            )
            #else
            .background(Color.gray.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
            #endif
        }
    }
}

#Preview {
    BranchIndicator(branchPath: []) {
        print("Return to main")
    }
}
