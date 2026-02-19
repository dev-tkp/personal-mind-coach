# Swift Package Manager (SPM) 사용 가이드

## 현재 상태

✅ **SPM 설치 확인**: Swift Package Manager - Swift 6.1.0  
✅ **프로젝트 준비 완료**: Xcode 프로젝트에서 SPM 패키지 추가 가능

## SPM이란?

Swift Package Manager는 Swift 언어의 공식 패키지 관리 도구입니다. CocoaPods나 Carthage 대신 Apple의 공식 도구를 사용하여 의존성을 관리합니다.

### 장점

- **공식 도구**: Apple이 직접 개발하고 유지보수
- **빠른 빌드**: 네이티브 통합으로 빌드 속도 향상
- **간단한 설정**: 별도의 `Podfile`이나 `Cartfile` 불필요
- **Xcode 통합**: Xcode에서 직접 패키지 추가/관리 가능

## Xcode에서 패키지 추가하기

### 방법 1: Xcode GUI 사용 (권장)

1. **Xcode에서 프로젝트 열기**
   ```bash
   open personal-mind-coach.xcodeproj
   ```

2. **프로젝트 네비게이터에서 프로젝트 선택**
   - 왼쪽 사이드바에서 최상단 프로젝트 아이콘 클릭

3. **Package Dependencies 탭 선택**
   - 프로젝트 설정에서 "Package Dependencies" 탭 클릭

4. **패키지 추가**
   - "+" 버튼 클릭
   - GitHub URL 또는 패키지 URL 입력
   - 버전 선택 (Up to Next Major Version 권장)
   - "Add Package" 클릭

5. **타겟에 추가**
   - 추가할 타겟 선택 (personal-mind-coach)
   - "Add to Target" 클릭

### 방법 2: 터미널에서 Package.swift 생성 (고급)

프로젝트 루트에 `Package.swift` 파일을 생성하여 패키지를 관리할 수도 있습니다:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "personal-mind-coach",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        // 예시: Alamofire 네트워킹 라이브러리
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        
        // 예시: SwiftUI 추가 기능
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "personal-mind-coach",
            dependencies: [
                "Alamofire",
                // 다른 의존성...
            ]
        )
    ]
)
```

## 일반적으로 사용하는 패키지 예시

### 네트워킹
```swift
// Alamofire - HTTP 네트워킹 라이브러리
.package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0")
```

### JSON 파싱
```swift
// SwiftyJSON - JSON 처리
.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0")
```

### 이미지 로딩
```swift
// Kingfisher - 이미지 다운로드 및 캐싱
.package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
```

### 데이터베이스
```swift
// GRDB - SQLite 데이터베이스
.package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0")
```

### UI 컴포넌트
```swift
// SwiftUI-Introspect - SwiftUI 내부 UIKit 접근
.package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.12.0")
```

## SPM 명령어 (터미널)

### 패키지 해결 및 업데이트

```bash
# 패키지 의존성 해결
swift package resolve

# 패키지 업데이트
swift package update

# 특정 패키지 업데이트
swift package update <package-name>

# 패키지 정리
swift package clean
```

### 빌드 및 테스트

```bash
# 빌드
swift build

# 릴리즈 빌드
swift build -c release

# 테스트 실행
swift test
```

### 패키지 정보 확인

```bash
# 패키지 의존성 트리 확인
swift package show-dependencies

# 패키지 설명 확인
swift package describe
```

## Xcode 프로젝트에서 SPM 사용 시 주의사항

1. **Package.resolved 파일**: 패키지 버전이 고정된 파일입니다. Git에 커밋해야 합니다.
2. **DerivedData**: 패키지가 `~/Library/Developer/Xcode/DerivedData`에 다운로드됩니다.
3. **네트워크**: 첫 빌드 시 패키지를 다운로드하므로 인터넷 연결이 필요합니다.

## 문제 해결

### 패키지 다운로드 실패

```bash
# DerivedData 정리
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Xcode에서 File > Packages > Reset Package Caches
```

### 패키지 버전 충돌

Xcode에서 프로젝트 설정 > Package Dependencies에서 버전을 조정하세요.

### 빌드 에러

```bash
# 패키지 재해결
swift package resolve

# Xcode에서 Product > Clean Build Folder (Cmd+Shift+K)
```

## Makefile에 SPM 명령어 추가

프로젝트의 `Makefile`에 다음 명령어를 추가할 수 있습니다:

```makefile
spm-resolve: ## SPM 패키지 의존성 해결
	@swift package resolve

spm-update: ## SPM 패키지 업데이트
	@swift package update

spm-clean: ## SPM 패키지 정리
	@swift package clean
```

## 참고 자료

- [Swift Package Manager 공식 문서](https://www.swift.org/package-manager/)
- [Apple Developer - Adding Package Dependencies](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [Swift Package Index](https://swiftpackageindex.com/) - 패키지 검색
