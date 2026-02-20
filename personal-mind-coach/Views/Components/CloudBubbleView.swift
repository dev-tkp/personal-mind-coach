//
//  CloudBubbleView.swift
//  personal-mind-coach
//
//  모핑 구름 배경 + Message 텍스트 + 브랜치 버튼(코치만). DesignSystem 전면 적용.
//

import SwiftUI
import SwiftData

struct CloudBubbleView: View {
    let message: Message
    /// 부모가 제공하는 가용 너비(예: ScrollView 너비). nil이면 400 사용.
    var availableWidth: CGFloat? = nil
    var onBranchTap: ((UUID) -> Void)? = nil
    var onDelete: ((UUID) -> Void)? = nil
    
    @State private var showDeleteConfirmation = false
    @State private var appeared = false
    
    private var style: CloudBubbleStyle {
        message.messageRole == .user ? .user : .coach
    }
    
    private var maxBubbleWidth: CGFloat {
        let width = availableWidth ?? 400
        return width * DesignSystem.cloudMaxWidthRatio
    }
    
    var body: some View {
        bubbleContent(maxWidth: maxBubbleWidth)
            .frame(minHeight: DesignSystem.cloudMinHeight)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.95)
            .animation(.cloudAppear, value: appeared)
            .onAppear { appeared = true }
        .confirmationDialog(
            String(localized: "메시지 삭제"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "삭제"), role: .destructive) {
                onDelete?(message.id)
            }
            Button(String(localized: "취소"), role: .cancel) {}
        } message: {
            Text("이 메시지와 하위 브랜치를 모두 삭제하시겠습니까?")
        }
    }
    
    @ViewBuilder
    private func bubbleContent(maxWidth: CGFloat) -> some View {
        VStack(alignment: message.messageRole == .user ? .trailing : .leading, spacing: 4) {
            // 모핑 구름 배경 위에 텍스트
            Text(message.content)
                .font(.thoughtBody)
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, DesignSystem.cloudPadding)
                .padding(.vertical, DesignSystem.cloudVerticalPadding)
                .frame(maxWidth: maxWidth, minHeight: DesignSystem.cloudMinHeight, alignment: .topLeading)
                .background(
                    MorphingCloudView(style: style)
                        .clipShape(RoundedRectangle(cornerRadius: .cloudCornerRadius))
                )
                .shadow(
                    color: Color.black.opacity(DesignSystem.cloudShadowOpacity),
                    radius: DesignSystem.cloudShadowRadius,
                    x: 0,
                    y: 2
                )
                .onLongPressGesture {
                    showDeleteConfirmation = true
                }
                .accessibilityLabel(message.messageRole == .user ? String(localized: "사용자 메시지") : String(localized: "상담가 응답"))
                .accessibilityIdentifier(message.messageRole == .user ? "userMessage" : "modelMessage")
                .accessibilityHint(String(localized: "길게 눌러 삭제할 수 있습니다"))
            
            if message.messageRole == .model, let onBranchTap = onBranchTap {
                branchButton(onTap: { onBranchTap(message.id) })
                    .padding(.top, 4)
            }
            
            Text(message.createdAt, style: .time)
                .font(.thoughtCaption)
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: maxWidth, alignment: message.messageRole == .user ? .trailing : .leading)
    }
    
    /// DesignSystem.branchButtonSize, accentBranch 적용
    private func branchButton(onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: DesignSystem.branchButtonSize, height: DesignSystem.branchButtonSize)
                .background(Color.accentBranch)
                .clipShape(Circle())
        }
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityLabel(String(localized: "여기서 더 물어보기"))
        .accessibilityIdentifier("branchButton")
        .accessibilityHint(String(localized: "이 답변에 대해 추가 질문을 할 수 있습니다"))
    }
}

// MARK: - Preview

#Preview("CloudBubbleView") {
    VStack(alignment: .leading, spacing: .spacingStandard) {
        CloudBubbleView(
            message: Message(role: .user, content: "요즘 일이 많아서 스트레스가 쌓여요."),
            onBranchTap: nil,
            onDelete: nil
        )
        
        CloudBubbleView(
            message: Message(role: .model, content: "일이 많을 때 스트레스를 느끼시는군요. 그런 감정을 느끼는 것은 자연스러운 일이에요. 혹시 그 스트레스가 몸이나 마음에 어떤 식으로 나타나나요?"),
            onBranchTap: { _ in },
            onDelete: nil
        )
    }
    .padding(.horizontal, .spacingStandard)
    .padding(.vertical, .spacingWide)
    .background(Color.bgMain)
    .modelContainer(for: Message.self)
}
