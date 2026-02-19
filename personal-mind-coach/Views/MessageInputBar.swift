//
//  MessageInputBar.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MessageInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("메시지를 입력하세요", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .disabled(isLoading)
                .accessibilityLabel("메시지 입력창")
            
            Button {
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                onSend(text)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(text.isEmpty || isLoading ? .gray : .blue)
            }
            .disabled(text.isEmpty || isLoading)
            .accessibilityLabel("전송")
            .accessibilityHint(text.isEmpty ? "메시지를 입력하세요" : "메시지 전송")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if canImport(UIKit)
        .background(Color(UIColor.systemBackground))
        #else
        .background(Color(.background))
        #endif
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
}

#Preview {
    MessageInputBar(text: .constant(""), isLoading: false) { _ in }
}
