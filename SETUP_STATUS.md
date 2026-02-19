# Fastlane 설정 상태 및 설치 가이드

## ✅ 설정 파일 검증 완료

### 1. 파일 구조 확인
```
fastlane/
├── Appfile              ✓ (문법 검증 완료)
├── Fastfile             ✓ (문법 검증 완료)
└── AuthKey_Q53SPL7242.p8 ✓ (파일 존재 확인)
```

### 2. API 키 설정
- **Key ID**: `Q53SPL7242` (파일명에서 자동 추출)
- **Issuer ID**: `6f223f6e-9fcc-4da7-ba02-caf066f554b9`
- **키 파일**: `fastlane/AuthKey_Q53SPL7242.p8` ✓

### 3. Fastfile 설정
- **프로젝트 이름**: `PersonalMindCoach`
- **Scheme**: `PersonalMindCoach`
- **사용 가능한 lanes**:
  - `beta` - TestFlight 베타 배포
  - `release` - App Store 프로덕션 배포
  - `build_only` - 로컬 빌드만
  - `beta_with_tests` - 테스트 후 배포

## ⚠️ Ruby 버전 업그레이드 필요

**현재 상태:**
- 시스템 Ruby: `2.6.10` (Fastlane 요구사항 미달)
- Fastlane 요구사항: Ruby `>= 2.7.0`

**해결 방법:**

### 방법 1: Homebrew로 Ruby 설치 (권장)

```bash
# 1. Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Ruby 설치
brew install ruby

# 3. PATH에 추가 (Apple Silicon Mac)
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 4. Fastlane 설치
gem install fastlane
```

### 방법 2: rbenv로 Ruby 설치

```bash
# 1. rbenv 설치
brew install rbenv ruby-build

# 2. rbenv 초기화
rbenv init
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

# 3. Ruby 3.2.0 설치
rbenv install 3.2.0
rbenv global 3.2.0

# 4. Fastlane 설치
gem install fastlane
```

### 방법 3: 시스템 Ruby 사용 (비권장)

```bash
# domain_name gem을 먼저 설치
gem install domain_name -v 0.5.20190701

# 그 다음 Fastlane 설치 시도 (성공하지 않을 수 있음)
gem install fastlane --user-install
```

## 🧪 설치 후 테스트

Ruby 업그레이드 및 Fastlane 설치 후:

```bash
# 1. Fastlane 버전 확인
fastlane --version

# 2. 설정 테스트
./test-fastlane.sh

# 3. Lanes 확인
fastlane lanes

# 4. 배포 테스트 (프로젝트 파일 준비 후)
fastlane beta
```

## 📝 다음 단계

1. ✅ **설정 파일 준비 완료** - 모든 설정 파일이 올바르게 구성됨
2. ⏳ **Ruby 업그레이드 필요** - 위의 방법 중 하나로 Ruby 업그레이드
3. ⏳ **Fastlane 설치** - Ruby 업그레이드 후 Fastlane 설치
4. ⏳ **프로젝트 파일 확인** - Xcode 프로젝트 파일(.xcodeproj 또는 .xcworkspace) 준비
5. ⏳ **배포 테스트** - `fastlane beta` 명령어로 배포 테스트

## 🔍 현재 상태 요약

| 항목 | 상태 | 비고 |
|------|------|------|
| Fastfile | ✅ 준비 완료 | 문법 검증 통과 |
| Appfile | ✅ 준비 완료 | API 키 경로 설정됨 |
| API 키 파일 | ✅ 준비 완료 | AuthKey_Q53SPL7242.p8 |
| Ruby 버전 | ⚠️ 업그레이드 필요 | 현재: 2.6.10, 필요: >= 2.7.0 |
| Fastlane 설치 | ⏳ 대기 중 | Ruby 업그레이드 후 설치 가능 |

**결론**: 모든 설정 파일은 준비되었습니다. Ruby를 업그레이드하면 바로 Fastlane을 설치하고 사용할 수 있습니다.
