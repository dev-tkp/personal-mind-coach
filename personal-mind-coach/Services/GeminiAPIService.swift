//
//  GeminiAPIService.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/19/26.
//

import Foundation

@MainActor
class GeminiAPIService: ObservableObject {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let model = "gemini-2.5-pro"
    
    private var apiKey: String {
        get throws {
            if let key = try? KeychainService.load(), !key.isEmpty {
                return key
            }
            // 기본 API 키 (나중에 Keychain에 저장하도록 안내)
            return "AIzaSyD95zh3JhAmO3wIrt-RDSX6IIQ4y_V7-q0"
        }
    }
    
    func generateContent(
        messages: [MessageContent],
        systemInstruction: String
    ) async throws -> String {
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await performRequest(messages: messages, systemInstruction: systemInstruction)
            } catch GeminiAPIError.rateLimitExceeded {
                lastError = error
                if attempt < maxRetries - 1 {
                    // Exponential backoff: 2^attempt 초 대기
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw error
            } catch {
                lastError = error
                if attempt < maxRetries - 1 && (error as? GeminiAPIError) == .serverError(500) {
                    // 서버 에러의 경우 재시도
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw error
            }
        }
        
        throw lastError ?? GeminiAPIError.invalidResponse
    }
    
    private func performRequest(
        messages: [MessageContent],
        systemInstruction: String
    ) async throws -> String {
        let apiKey = try apiKey
        let url = URL(string: "\(baseURL)/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 30.0
        
        let requestBody: [String: Any] = [
            "contents": messages.map { message in
                [
                    "role": message.role,
                    "parts": [["text": message.text]]
                ]
            },
            "systemInstruction": [
                "parts": [["text": systemInstruction]]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 8192
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        AppLogger.api.debug("📤 Gemini API Request to \(url.absoluteString)")
        #if DEBUG
        if let jsonData = request.httpBody,
           let jsonString = String(data: jsonData, encoding: .utf8) {
            AppLogger.api.debug("Request body: \(jsonString.prefix(500))...")
        }
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiAPIError.invalidResponse
        }
        
        AppLogger.api.debug("📥 Gemini API Response Status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 429 {
                throw GeminiAPIError.rateLimitExceeded
            } else if httpResponse.statusCode == 401 {
                throw GeminiAPIError.unauthorized
            } else if httpResponse.statusCode == 400 {
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("❌ Bad Request Error: \(errorData)")
                }
                throw GeminiAPIError.badRequest
            } else {
                throw GeminiAPIError.serverError(httpResponse.statusCode)
            }
        }
        
        let decoder = JSONDecoder()
        let responseModel = try decoder.decode(GeminiResponse.self, from: data)
        
        guard let candidate = responseModel.candidates.first,
              let text = candidate.content.parts.first?.text else {
            throw GeminiAPIError.noContent
        }
        
        if let usage = responseModel.usageMetadata {
            AppLogger.api.info("📊 Token Usage: prompt=\(usage.promptTokenCount ?? 0), candidates=\(usage.candidatesTokenCount ?? 0), total=\(usage.totalTokenCount ?? 0)")
        }
        
        return text
    }
}

struct MessageContent {
    let role: String  // "user" or "model"
    let text: String
}

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

enum GeminiAPIError: Error, LocalizedError {
    case invalidResponse
    case rateLimitExceeded
    case unauthorized
    case badRequest
    case serverError(Int)
    case noContent
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "잘못된 응답입니다."
        case .rateLimitExceeded:
            return "요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요."
        case .unauthorized:
            return "인증에 실패했습니다. API 키를 확인해주세요."
        case .badRequest:
            return "잘못된 요청입니다."
        case .serverError(let code):
            return "서버 오류가 발생했습니다. (코드: \(code))"
        case .noContent:
            return "응답 내용을 받을 수 없습니다."
        case .decodingError:
            return "응답을 파싱할 수 없습니다."
        }
    }
}
