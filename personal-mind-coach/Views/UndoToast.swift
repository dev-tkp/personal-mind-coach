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
            HStack {
                Text("메시지가 삭제되었습니다")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("실행 취소") {
                    onUndo()
                    isVisible = false
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
            .padding(.horizontal)
            .transition(.move(edge: .bottom))
            .onAppear {
                // 3초 후 자동으로 사라짐
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isVisible = false
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
