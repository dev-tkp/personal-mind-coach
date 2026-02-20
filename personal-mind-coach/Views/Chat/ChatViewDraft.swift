//
//  ChatViewDraft.swift
//  personal-mind-coach
//
//  CloudBubbleView만 사용하는 최소 채팅 목업. 실데이터/ViewModel 없이 샘플 메시지로 레이아웃 확인용.
//

import SwiftUI
import SwiftData

/// 모핑 구름 UI 연동 전용 초안. 실제 앱은 Views/ChatView.swift 사용.
struct ChatViewDraft: View {
    private let sampleMessages: [Message] = [
        Message(role: .user, content: "요즘 일이 많아서 스트레스가 쌓여요."),
        Message(role: .model, content: "일이 많을 때 스트레스를 느끼시는군요. 그런 감정을 느끼는 것은 자연스러운 일이에요. 혹시 그 스트레스가 몸이나 마음에 어떤 식으로 나타나나요?"),
        Message(role: .user, content: "잠을 잘 못 자요."),
        Message(role: .model, content: "수면에 영향을 주고 계시는군요. 괜찮으시다면, 평소 몇 시쯤 누우시고 몇 시에 일어나시나요?")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                GeometryReader { geo in
                    LazyVStack(alignment: .leading, spacing: .spacingStandard) {
                        ForEach(sampleMessages) { message in
                            HStack {
                                if message.messageRole == .user {
                                    Spacer()
                                }
                                CloudBubbleView(
                                    message: message,
                                    availableWidth: geo.size.width,
                                    onBranchTap: message.messageRole == .model ? { _ in } : nil,
                                    onDelete: nil
                                )
                                if message.messageRole == .model {
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, .spacingStandard)
                .padding(.vertical, .spacingWide)
            }
            .background(Color.bgMain)
            .navigationTitle("마인드 코치")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

#Preview("ChatViewDraft") {
    ChatViewDraft()
        .modelContainer(for: Message.self)
}
