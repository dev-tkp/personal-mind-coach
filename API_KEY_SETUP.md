# API 키 설정 가이드

## ⚠️ 중요 알림

제공하신 API 키 (`AIzaSyD95zh3JhAmO3wIrt-RDSX6IIQ4y_V7-q0`)가 유출된 것으로 보고되어 사용할 수 없습니다.

**에러 메시지**: "Your API key was reported as leaked. Please use another API key."

## 해결 방법

### 1. 새로운 API 키 생성

1. [Google AI Studio](https://aistudio.google.com/app/apikey)에 접속
2. 새 API 키 생성
3. 생성된 키를 안전하게 보관

### 2. API 키 설정 방법

#### 방법 1: 환경변수 설정 (권장)

터미널에서:
```bash
export GEMINI_API_KEY="YOUR_NEW_API_KEY"
```

앱 실행 시 환경변수에서 자동으로 읽어옵니다.

#### 방법 2: Keychain에 직접 저장

스크립트 사용:
```bash
# setup_api_key.swift 파일 수정 후 실행
swift setup_api_key.swift
```

또는 코드에서 직접:
```swift
try KeychainService.save("YOUR_NEW_API_KEY")
```

#### 방법 3: 앱 내 설정 화면 (향후 구현)

앱 내에서 설정 화면을 통해 API 키를 입력하고 저장할 수 있습니다.

## 현재 상태

- ✅ API 키 저장 로직: 구현 완료
- ✅ Keychain 서비스: 구현 완료
- ✅ 환경변수 지원: 구현 완료
- ⚠️ API 키: 새로운 키 필요

## 테스트

새로운 API 키를 설정한 후:

```bash
# 환경변수 설정
export GEMINI_API_KEY="YOUR_NEW_API_KEY"

# 테스트 실행
swift test_gemini_api.swift
```

## 보안 권장사항

1. **절대 코드에 API 키를 하드코딩하지 마세요**
2. **Git에 API 키를 커밋하지 마세요** (이미 .gitignore에 설정됨)
3. **Keychain 사용**: iOS Keychain은 가장 안전한 저장 방법입니다
4. **환경변수 사용**: 개발 중에는 환경변수 사용 권장

## 모델 정보

현재 사용 중인 모델:
- `gemini-3-flash-preview` (기본)
- `gemini-2.5-pro` (대안)

모델은 `GeminiAPIService.swift`에서 변경 가능합니다.
