# Personal Mind Coach

나만을 위한 마인드 코치 앱 - 전용 심리상담 에이전트 iPhone 앱

## 프로젝트 개요

Personal Mind Coach는 Gemini API를 활용한 개인 맞춤형 심리상담 앱입니다. 단일 세션, 영구 백그라운드 저장, 브랜치 질문, 삭제(undo) 기능을 제공합니다.

## 주요 기능

- **단일 세션**: 연속된 대화 히스토리 유지
- **영구 저장**: 상담 히스토리 및 백그라운드 정보 저장
- **브랜치 질문**: 특정 답변에서 깊이 탐색 가능
- **삭제(Undo)**: 메시지 삭제 시 백그라운드 정보도 함께 제거
- **고품질 응답**: Gemini API 기반 전문 상담가 역할

## 기술 스택

- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Dependency Management**: Swift Package Manager (SPM)
- **API**: Google Gemini API
- **Database**: SwiftData
- **Build Tool**: Xcode, Fastlane

## 요구사항

- iOS 17.0+
- Xcode 15.0+
- Swift 6.0+

## 설치 및 실행

### 1. 저장소 클론

```bash
git clone https://github.com/dev-tkp/personal-mind-coach.git
cd personal-mind-coach
```

### 2. 의존성 설치

```bash
# Homebrew 설치 (필요한 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 도구 설치
make install-deps

# 또는 개별 설치
brew install xcbeautify
brew install fastlane
```

### 3. Xcode에서 프로젝트 열기

```bash
open personal-mind-coach.xcodeproj
```

### 4. 빌드 및 실행

```bash
# 빌드
make build

# 또는 직접 빌드
./build.sh
```

## 개발 가이드

### 빌드

```bash
make build          # 프로젝트 빌드
make clean          # 빌드 캐시 정리
```

### SPM 패키지 관리

```bash
make spm-resolve    # 패키지 의존성 해결
make spm-update     # 패키지 업데이트
make spm-show-deps  # 의존성 트리 확인
```

### 배포 (Fastlane)

```bash
make deploy-beta    # TestFlight에 베타 배포
make deploy-release # App Store에 프로덕션 배포
make build-ipa      # 로컬에만 빌드 (업로드 없음)
```

## 프로젝트 구조

```
personal-mind-coach/
├── personal-mind-coach/          # 메인 앱 소스 코드
├── personal-mind-coachTests/     # 단위 테스트
├── personal-mind-coachUITests/   # UI 테스트
├── fastlane/                     # Fastlane 배포 설정
├── .cursor/                      # Cursor AI 설정
│   ├── mind-coach-PRD.plan.md   # 프로젝트 기획서
│   └── rules/                    # 개발 규칙
├── build.sh                      # 빌드 스크립트
├── Makefile                      # 빌드 명령어
└── README.md                     # 이 파일
```

## 문서

- [프로젝트 기획서](.cursor/mind-coach-PRD.plan.md)
- [설치 가이드](INSTALLATION_GUIDE.md)
- [SPM 사용 가이드](SPM_GUIDE.md)
- [iOS 엔지니어링 원칙](.cursor/rules/ios-engineering-principles.mdc)

## 라이선스

이 프로젝트는 개인 프로젝트입니다.

## 기여

이슈 및 풀 리퀘스트를 환영합니다.

## 연락처

프로젝트 관련 문의사항은 GitHub Issues를 통해 제출해주세요.
