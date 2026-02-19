//
//  personal_mind_coachApp.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import SwiftUI
import SwiftData

@main
struct personal_mind_coachApp: App {
    init() {
        // 앱 시작 시 API 키가 Keychain에 없으면 기본 키 저장 시도
        Task { @MainActor in
            if (try? KeychainService.load()) == nil {
                // 환경변수에서 API 키 확인
                if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
                    try? KeychainService.save(envKey)
                    AppLogger.general.info("환경변수에서 API 키가 Keychain에 저장되었습니다.")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
        .modelContainer(for: [Message.self, Session.self, Background.self, ConversationSummary.self])
    }
}
