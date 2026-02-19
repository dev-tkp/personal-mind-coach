# 빌드 및 배포 가이드

## 현재 상태

✅ **코드 구현**: 완료
✅ **코드 검증**: 린터 오류 없음
⚠️ **빌드 환경**: Xcode 앱 설치 필요

---

## Xcode 설치 및 설정

### 1. Xcode 설치

```bash
# App Store에서 Xcode 설치
# 또는
# https://developer.apple.com/xcode/ 에서 다운로드
```

### 2. Xcode Command Line Tools 설정

```bash
# Xcode 앱 설치 후 실행하여 라이선스 동의
sudo xcodebuild -license accept

# Xcode 경로 설정
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### 3. 확인

```bash
# Xcode 경로 확인
xcode-select -p
# 출력: /Applications/Xcode.app/Contents/Developer

# Xcode 버전 확인
xcodebuild -version
```

---

## 빌드 방법

### 방법 1: Xcode GUI 사용 (권장)

1. **프로젝트 열기**
   ```bash
   open personal-mind-coach.xcodeproj
   ```

2. **스키마 선택**
   - 상단 툴바에서 "personal-mind-coach" 스키마 선택
   - 시뮬레이터 선택 (예: iPhone 15)

3. **빌드 및 실행**
   - `Cmd + R` 또는 상단의 재생 버튼 클릭

### 방법 2: Command Line 사용

#### 시뮬레이터 빌드

```bash
# 기본 빌드 스크립트 사용
./build.sh

# 또는 직접 빌드
xcodebuild -project personal-mind-coach.xcodeproj \
  -scheme personal-mind-coach \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  clean build
```

#### 실제 기기 빌드

```bash
# 개발 빌드 (서명 필요)
xcodebuild -project personal-mind-coach.xcodeproj \
  -scheme personal-mind-coach \
  -sdk iphoneos \
  -configuration Debug \
  CODE_SIGN_IDENTITY="Apple Development" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
  clean build

# 릴리스 빌드
xcodebuild -project personal-mind-coach.xcodeproj \
  -scheme personal-mind-coach \
  -sdk iphoneos \
  -configuration Release \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
  clean build
```

---

## 빌드 전 확인 사항

### 1. 프로젝트 설정 확인

- **Bundle Identifier**: `com.personalmindcoach` (또는 고유한 값)
- **Deployment Target**: iOS 17.0+
- **Signing & Capabilities**: 개발자 계정 설정

### 2. API 키 설정

기본 API 키가 코드에 포함되어 있지만, 프로덕션에서는 Keychain에 저장하도록 안내:

```swift
// KeychainService를 사용하여 API 키 저장
try KeychainService.save("YOUR_API_KEY")
```

### 3. 의존성 확인

현재 프로젝트는 외부 의존성 없이 기본 프레임워크만 사용:
- SwiftUI
- SwiftData
- Foundation

---

## 빌드 에러 해결

### 일반적인 에러

1. **"No such module 'SwiftUI'"**
   - Xcode 버전 확인 (iOS 17+ 지원 필요)
   - 프로젝트 타겟 iOS 버전 확인

2. **Signing 에러**
   - 개발자 계정 설정
   - Bundle Identifier 고유성 확인

3. **Swift 버전 에러**
   - Xcode 15.0+ 필요 (Swift 6.0 지원)

---

## 테스트 실행

### 시뮬레이터에서 테스트

```bash
# 시뮬레이터 실행
xcrun simctl boot "iPhone 15"

# 앱 설치 및 실행
xcodebuild -project personal-mind-coach.xcodeproj \
  -scheme personal-mind-coach \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

### 실제 기기에서 테스트

1. Xcode에서 기기 연결
2. 신뢰 설정 (기기에서)
3. 개발자 계정으로 서명
4. 실행

---

## 배포 준비

### 1. 버전 관리

`Info.plist` 또는 프로젝트 설정에서:
- **Version**: 1.0.0
- **Build**: 1

### 2. App Store Connect 설정

1. App Store Connect에서 앱 생성
2. Bundle ID 등록
3. 앱 정보 입력

### 3. Archive 생성

```bash
# Archive 빌드
xcodebuild -project personal-mind-coach.xcodeproj \
  -scheme personal-mind-coach \
  -configuration Release \
  -archivePath ./build/personal-mind-coach.xcarchive \
  archive
```

### 4. 배포

#### TestFlight (베타 테스트)

```bash
# Fastlane 사용 (설정된 경우)
fastlane beta

# 또는 Xcode에서 직접
# Product > Archive > Distribute App > TestFlight
```

#### App Store

```bash
# Fastlane 사용
fastlane release

# 또는 Xcode에서 직접
# Product > Archive > Distribute App > App Store Connect
```

---

## 로그 확인

### Xcode 콘솔

빌드 및 실행 중 로그 확인:
- API 요청/응답: `📤 📥` 이모지로 필터링
- 토큰 사용량: `📊` 이모지로 필터링
- 에러: `❌` 이모지로 필터링

### 시스템 로그

```bash
# Console 앱에서 확인
# 또는
log stream --predicate 'subsystem == "com.personalmindcoach"'
```

---

## 성능 프로파일링

### Instruments 사용

1. Xcode에서 `Product > Profile` (Cmd + I)
2. 원하는 템플릿 선택:
   - **Time Profiler**: CPU 사용량
   - **Allocations**: 메모리 사용량
   - **Network**: 네트워크 활동

### 메모리 누수 확인

```bash
# Leaks 템플릿 사용
# 또는 코드에서 강한 참조 순환 확인
```

---

## 알려진 이슈 및 해결 방법

### 1. Xcode 미설치

**문제**: `xcode-select: error: tool 'xcodebuild' requires Xcode`

**해결**:
1. App Store에서 Xcode 설치
2. `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

### 2. 시뮬레이터 없음

**문제**: 지정된 시뮬레이터를 찾을 수 없음

**해결**:
```bash
# 사용 가능한 시뮬레이터 확인
xcrun simctl list devices

# 시뮬레이터 이름 변경 또는 새로 생성
```

### 3. 서명 에러

**문제**: Code signing 에러

**해결**:
1. Xcode > Preferences > Accounts에서 개발자 계정 추가
2. 프로젝트 설정 > Signing & Capabilities에서 자동 서명 활성화

---

## 다음 단계

1. ✅ Xcode 설치 및 설정
2. ✅ 프로젝트 빌드
3. ⏭️ 시뮬레이터에서 기본 기능 테스트
4. ⏭️ 실제 기기에서 전체 테스트
5. ⏭️ TestFlight 베타 테스트 (선택)
6. ⏭️ App Store 배포 (선택)

---

## 참고 문서

- [테스트 시나리오](./TEST_SCENARIOS.md)
- [코드 재검토 결과](./CODE_REVIEW.md)
- [프로젝트 기획서](.cursor/mind-coach-PRD.plan.md)
