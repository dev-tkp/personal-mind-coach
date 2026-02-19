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
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
        .modelContainer(for: [Message.self, Session.self, Background.self, ConversationSummary.self])
    }
}
