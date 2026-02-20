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
    private let model = "gemini-3-flash-preview"  // gemini-3-flash-preview 또는 gemini-2.5-pro 사용 가능
    
    private var apiKey: String {
        get throws {
            // 1. Keychain에서 API 키 확인
            if let key = try? KeychainService.load(), !key.isEmpty {
                AppLogger.api.debug("✅ Keychain에서 API 키 로드 성공")
                return key
            }
            
            // 2. 환경변수에서 API 키 확인
            if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
                AppLogger.api.debug("✅ 환경변수에서 API 키 발견, Keychain에 저장 중...")
                // 환경변수에서 찾은 키를 Keychain에 저장
                try? KeychainService.save(envKey)
                return envKey
            }
            
            // 3. API 키가 없으면 에러 발생
            AppLogger.api.error("❌ API 키를 찾을 수 없습니다. Keychain과 환경변수를 확인해주세요.")
            throw GeminiAPIError.unauthorized
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
                let response = try await performRequest(messages: messages, systemInstruction: systemInstruction)
                
                // 빈 응답 체크 및 재시도
                if response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    AppLogger.api.warning("⚠️ 빈 응답 수신 (시도 \(attempt + 1)/\(maxRetries))")
                    if attempt < maxRetries - 1 {
                        let delay = pow(2.0, Double(attempt))
                        AppLogger.api.debug("⏳ \(delay)초 후 재시도...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    } else {
                        throw GeminiAPIError.noContent
                    }
                }
                
                return response
            } catch let error as GeminiAPIError {
                lastError = error
                
                // Rate limit 또는 서버 에러(500)인 경우 재시도
                let shouldRetry: Bool
                switch error {
                case .rateLimitExceeded:
                    shouldRetry = true
                case .serverError(let code) where code == 500:
                    shouldRetry = true
                case .noContent:
                    // 빈 응답도 재시도
                    shouldRetry = attempt < maxRetries - 1
                default:
                    shouldRetry = false
                }
                
                if shouldRetry && attempt < maxRetries - 1 {
                    // Exponential backoff: 2^attempt 초 대기
                    let delay = pow(2.0, Double(attempt))
                    AppLogger.api.debug("⏳ \(delay)초 후 재시도...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                throw error
            } catch {
                lastError = error
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
        
        // API 키 검증 로깅 (키의 일부만 표시)
        let maskedKey = String(apiKey.prefix(10)) + "..." + String(apiKey.suffix(4))
        AppLogger.api.debug("🔑 API 키 사용 중: \(maskedKey)")
        
        let url = URL(string: "\(baseURL)/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 30.0
        
        // 헤더 확인 로깅
        #if DEBUG
        if let headerValue = request.value(forHTTPHeaderField: "x-goog-api-key") {
            let maskedHeader = String(headerValue.prefix(10)) + "..." + String(headerValue.suffix(4))
            AppLogger.api.debug("📋 x-goog-api-key 헤더 설정됨: \(maskedHeader)")
        } else {
            AppLogger.api.error("❌ x-goog-api-key 헤더가 설정되지 않음!")
        }
        #endif
        
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
            // 요청 본문 전체 로깅 (너무 길면 일부만)
            let fullBody = jsonString
            if fullBody.count > 2000 {
                AppLogger.api.debug("Request body (첫 1000자): \(fullBody.prefix(1000))...")
                AppLogger.api.debug("Request body (마지막 500자): ...\(fullBody.suffix(500))")
            } else {
                AppLogger.api.debug("Request body: \(fullBody)")
            }
            
            // 메시지 구조 확인
            if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let contents = jsonObject["contents"] as? [[String: Any]] {
                AppLogger.api.debug("📋 요청 메시지 구조:")
                for (index, content) in contents.enumerated() {
                    let role = content["role"] as? String ?? "unknown"
                    if let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let text = firstPart["text"] as? String {
                        let preview = text.prefix(100)
                        AppLogger.api.debug("  [\(index)] role=\(role), text=\(preview)\(text.count > 100 ? "..." : "")")
                    }
                }
            }
        }
        #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiAPIError.invalidResponse
        }
        
        AppLogger.api.debug("📥 Gemini API Response Status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // 에러 응답 본문 로깅
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = errorData["error"] as? [String: Any] {
                let errorMessage = errorInfo["message"] as? String ?? "알 수 없는 에러"
                let errorStatus = errorInfo["status"] as? String ?? "UNKNOWN"
                AppLogger.api.error("❌ API 에러 (\(httpResponse.statusCode)): \(errorStatus) - \(errorMessage)")
            } else if let errorString = String(data: data, encoding: .utf8) {
                AppLogger.api.error("❌ API 에러 응답 (\(httpResponse.statusCode)): \(errorString.prefix(500))")
            }
            
            // 403 에러에 대한 특별 처리 추가
            if httpResponse.statusCode == 403 {
                AppLogger.api.error("❌ 403 Forbidden: API 키 권한이 없거나 잘못되었습니다. API 키를 확인해주세요.")
                throw GeminiAPIError.unauthorized  // 403도 인증 문제로 처리
            } else if httpResponse.statusCode == 429 {
                throw GeminiAPIError.rateLimitExceeded
            } else if httpResponse.statusCode == 401 {
                throw GeminiAPIError.unauthorized
            } else if httpResponse.statusCode == 400 {
                throw GeminiAPIError.badRequest
            } else {
                throw GeminiAPIError.serverError(httpResponse.statusCode)
            }
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let responseModel: GeminiResponse
        do {
            responseModel = try decoder.decode(GeminiResponse.self, from: data)
        } catch {
            AppLogger.api.error("❌ JSON 디코딩 실패: \(error.localizedDescription)")
            if let jsonString = String(data: data, encoding: .utf8) {
                AppLogger.api.error("응답 데이터: \(jsonString.prefix(1000))")
            }
            throw GeminiAPIError.decodingError
        }
        
        guard let candidate = responseModel.candidates.first else {
            AppLogger.api.error("❌ 응답에 candidate가 없음")
            // 응답 데이터 전체 로깅
            if let jsonString = String(data: data, encoding: .utf8) {
                AppLogger.api.error("응답 데이터 전체: \(jsonString)")
            }
            throw GeminiAPIError.noContent
        }
        
        // finishReason 확인
        if let finishReason = candidate.finishReason, finishReason != "STOP" {
            AppLogger.api.warning("⚠️ Finish reason: \(finishReason)")
        }
        
        // 디버깅: 응답 구조 확인
        AppLogger.api.debug("📋 Candidate 구조 확인:")
        AppLogger.api.debug("  - finishReason: \(candidate.finishReason ?? "nil")")
        AppLogger.api.debug("  - content.role: \(candidate.content.role)")
        AppLogger.api.debug("  - content.parts 개수: \(candidate.content.parts.count)")
        
        for (index, part) in candidate.content.parts.enumerated() {
            AppLogger.api.debug("  - parts[\(index)].text: \(part.text?.prefix(100) ?? "nil")")
        }
        
        // 텍스트 추출 시도
        var text: String? = nil
        
        // 방법 1: parts 배열에서 text 찾기
        for part in candidate.content.parts {
            if let partText = part.text, !partText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                text = partText
                break
            }
        }
        
        // 방법 2: parts가 비어있거나 text가 없는 경우 응답 데이터 직접 확인
        if text == nil {
            AppLogger.api.warning("⚠️ parts에서 text를 찾을 수 없음. 응답 데이터 재확인 중...")
            if let jsonString = String(data: data, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let candidates = jsonObject["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let partText = firstPart["text"] as? String,
               !partText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                text = partText
                AppLogger.api.debug("✅ JSON 직접 파싱으로 텍스트 추출 성공")
            }
        }
        
        guard let finalText = text, !finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            AppLogger.api.error("❌ 응답에 내용이 없음 (finishReason: \(candidate.finishReason ?? "unknown"))")
            // 응답 데이터 전체 로깅
            if let jsonString = String(data: data, encoding: .utf8) {
                AppLogger.api.error("응답 데이터 전체: \(jsonString.prefix(2000))")
            }
            throw GeminiAPIError.noContent
        }
        
        if let usage = responseModel.usageMetadata {
            AppLogger.api.info("📊 Token Usage: prompt=\(usage.promptTokenCount ?? 0), candidates=\(usage.candidatesTokenCount ?? 0), total=\(usage.totalTokenCount ?? 0)")
        }
        
        return finalText
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
    let thoughtSignature: String?  // Gemini 3.0의 새로운 필드
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
