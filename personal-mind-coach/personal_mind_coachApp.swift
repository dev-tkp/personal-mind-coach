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
                // 기본 API 키 저장 (나중에 사용자가 설정 화면에서 변경 가능)
                // 주의: 이 키는 유출되었을 수 있으므로 새로운 키로 교체 필요
                if let defaultKey = getDefaultAPIKey() {
                    try? KeychainService.save(defaultKey)
                    AppLogger.general.info("기본 API 키가 Keychain에 저장되었습니다.")
                }
            }
        }
    }
    
    private func getDefaultAPIKey() -> String? {
        // 환경변수에서 API 키 확인
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // 기본값 (유출된 키이므로 교체 필요)
        return nil
    }
    
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
        .modelContainer(for: [Message.self, Session.self, Background.self, ConversationSummary.self])
    }
}
