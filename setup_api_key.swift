#!/usr/bin/env swift

import Foundation
import Security

// API 키를 Keychain에 저장하는 스크립트
// 사용법: GEMINI_API_KEY="your-api-key" swift setup_api_key.swift
// 또는 아래 apiKey 변수를 직접 수정

let apiKey: String
if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
    apiKey = envKey
} else {
    // 여기에 API 키를 직접 입력하거나 환경변수 사용
    print("⚠️  환경변수 GEMINI_API_KEY가 설정되지 않았습니다.")
    print("사용법: GEMINI_API_KEY=\"your-api-key\" swift setup_api_key.swift")
    exit(1)
}
let service = "com.personalmindcoach.apiKey"
let account = "geminiAPIKey"

guard let data = apiKey.data(using: .utf8) else {
    print("❌ API 키를 데이터로 변환할 수 없습니다.")
    exit(1)
}

let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account,
    kSecValueData as String: data
]

// 기존 항목 삭제
SecItemDelete(query as CFDictionary)

// 새 항목 추가
let status = SecItemAdd(query as CFDictionary, nil)

if status == errSecSuccess {
    print("✅ API 키가 Keychain에 성공적으로 저장되었습니다.")
    exit(0)
} else {
    print("❌ API 키 저장 실패: \(status)")
    exit(1)
}
