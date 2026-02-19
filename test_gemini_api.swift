#!/usr/bin/env swift

import Foundation

// Gemini API 테스트 스크립트
// 사용법: GEMINI_API_KEY="your-api-key" swift test_gemini_api.swift

let apiKey: String
if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
    apiKey = envKey
} else {
    print("⚠️  환경변수 GEMINI_API_KEY가 설정되지 않았습니다.")
    print("사용법: GEMINI_API_KEY=\"your-api-key\" swift test_gemini_api.swift")
    exit(1)
}
let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
let model = "gemini-3-flash-preview"

let url = URL(string: "\(baseURL)/\(model):generateContent")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
request.timeoutInterval = 30.0

let requestBody: [String: Any] = [
    "contents": [
        [
            "role": "user",
            "parts": [["text": "Explain how AI works in a few words"]]
        ]
    ],
    "generationConfig": [
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 8192
    ]
]

do {
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    
    print("📤 API 요청 전송 중...")
    print("URL: \(url.absoluteString)")
    print("Model: \(model)")
    print("---")
    
    let semaphore = DispatchSemaphore(value: 0)
    var responseText: String?
    var errorMessage: String?
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            errorMessage = "네트워크 에러: \(error.localizedDescription)"
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "잘못된 응답 형식"
            return
        }
        
        print("📥 응답 상태 코드: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let data = data, let errorData = try? JSONSerialization.jsonObject(with: data) {
                errorMessage = "API 에러 (\(httpResponse.statusCode)): \(errorData)"
            } else {
                errorMessage = "API 에러: \(httpResponse.statusCode)"
            }
            return
        }
        
        guard let data = data else {
            errorMessage = "응답 데이터 없음"
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let responseModel = try decoder.decode(GeminiResponse.self, from: data)
            
            if let candidate = responseModel.candidates.first,
               let text = candidate.content.parts.first?.text {
                responseText = text
            } else {
                errorMessage = "응답 내용을 파싱할 수 없습니다"
            }
        } catch {
            errorMessage = "JSON 파싱 에러: \(error.localizedDescription)"
            if let jsonString = String(data: data, encoding: .utf8) {
                print("응답 데이터: \(jsonString.prefix(500))")
            }
        }
    }.resume()
    
    semaphore.wait()
    
    if let error = errorMessage {
        print("❌ \(error)")
        exit(1)
    }
    
    if let text = responseText {
        print("✅ API 호출 성공!")
        print("---")
        print("응답:")
        print(text)
        print("---")
        exit(0)
    } else {
        print("❌ 응답을 받을 수 없습니다")
        exit(1)
    }
    
} catch {
    print("❌ 요청 생성 실패: \(error.localizedDescription)")
    exit(1)
}

// 응답 모델 구조체
struct GeminiResponse: Codable {
    let candidates: [Candidate]
    let usageMetadata: UsageMetadata?
}

struct Candidate: Codable {
    let content: Content
    let finishReason: String?
    let safetyRatings: [SafetyRating]?
}

struct Content: Codable {
    let parts: [Part]
    let role: String
}

struct Part: Codable {
    let text: String?
}

struct SafetyRating: Codable {
    let category: String
    let probability: String
}

struct UsageMetadata: Codable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
}
