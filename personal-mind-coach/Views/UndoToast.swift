//
//  UndoToast.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI

struct UndoToast: View {
    let onUndo: () -> Void
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text("메시지가 삭제되었습니다")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("실행 취소") {
                    onUndo()
                    isVisible = false
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .accessibilityLabel("실행 취소")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.85))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                // 3초 후 자동으로 사라짐
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isVisible = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    UndoToast {
        print("Undo")
    }
}
