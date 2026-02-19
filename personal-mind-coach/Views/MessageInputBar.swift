//
//  MessageInputBar.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI

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
            
            Button {
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                onSend(text)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(text.isEmpty || isLoading ? .gray : .blue)
            }
            .disabled(text.isEmpty || isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    MessageInputBar(text: .constant(""), isLoading: false) { _ in }
}
