# Fastlane 설정 완료 확인

## ✅ 설정 완료 사항

### 1. API 키 정보
- **Key ID**: `Q53SPL7242`
- **Issuer ID**: `6f223f6e-9fcc-4da7-ba02-caf066f554b9`
- **키 파일**: `fastlane/AuthKey_Q53SPL7242.p8` ✓

### 2. 설정 파일
- ✅ `fastlane/Fastfile` - 배포 자동화 설정
- ✅ `fastlane/Appfile` - API 키 경로 설정됨
- ✅ `fastlane/AuthKey_Q53SPL7242.p8` - API 키 파일

## 🚀 Fastlane 설치 및 테스트

### 1. Fastlane 설치

**방법 1: Homebrew (권장)**
```bash
brew install fastlane
```

**방법 2: RubyGems**
```bash
sudo gem install fastlane
```

### 2. 설정 테스트

설치 후 다음 명령어로 설정을 확인하세요:

```bash
# 설정 테스트 스크립트 실행
./test-fastlane.sh

# 또는 직접 Fastlane lanes 확인
fastlane lanes
```

### 3. 배포 테스트

```bash
# TestFlight 베타 배포
fastlane beta
# 또는
make deploy-beta

# 로컬 빌드만 (업로드 없음)
fastlane build_only
# 또는
make build-ipa
```

## 📝 참고사항

1. **프로젝트 파일 확인 필요**
   - `Fastfile`의 `PROJECT_NAME`, `SCHEME`, `WORKSPACE` 값이 실제 프로젝트와 일치하는지 확인하세요
   - Xcode 프로젝트 파일(.xcodeproj 또는 .xcworkspace)이 있어야 빌드가 가능합니다

2. **API 키 인증**
   - Fastlane은 `Appfile`의 `api_key_path` 설정을 자동으로 인식합니다
   - Key ID는 파일명에서 자동 추출됩니다 (`AuthKey_Q53SPL7242.p8` → `Q53SPL7242`)

3. **첫 배포 전 확인사항**
   - Xcode에서 Signing & Capabilities 설정 확인
   - Provisioning Profile이 올바르게 설정되었는지 확인
   - App Store Connect에 앱이 등록되어 있는지 확인

## 🔧 문제 해결

### Fastlane이 설치되지 않는 경우
```bash
# Ruby 버전 확인
ruby --version

# RubyGems 업데이트
sudo gem update --system

# Fastlane 재설치
sudo gem install fastlane
```

### API 키 인증 에러
- API 키 파일이 `fastlane/` 디렉토리에 있는지 확인
- Key ID와 Issuer ID가 올바른지 확인
- App Store Connect에서 API 키 권한 확인
