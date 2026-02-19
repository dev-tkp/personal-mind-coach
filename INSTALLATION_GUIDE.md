# 설치 가이드

## 현재 상태

✅ **빌드 테스트 성공**: `./build.sh`로 빌드가 정상적으로 작동합니다.

## 필요한 설치 작업

### 1. Homebrew 설치 (필수)

Homebrew는 macOS용 패키지 관리자입니다. 터미널에서 다음 명령어를 실행하세요:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

설치 후 PATH 설정 (Apple Silicon Mac의 경우):
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"
```

설치 확인:
```bash
brew --version
```

### 2. Ruby 업그레이드 (필수)

현재 Ruby 버전: 2.6.10 (Fastlane은 Ruby 2.7.0 이상 필요)

#### 방법 1: Homebrew로 Ruby 설치 (권장)

```bash
brew install ruby
```

설치 후 PATH 설정:
```bash
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### 방법 2: rbenv 사용 (선택사항)

```bash
brew install rbenv ruby-build
rbenv install 3.2.0
rbenv global 3.2.0
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc
```

버전 확인:
```bash
ruby --version  # 2.7.0 이상이어야 함
```

### 3. xcbeautify 설치 (선택사항, 권장)

빌드 로그를 보기 좋게 만들어줍니다:

```bash
brew install xcbeautify
```

### 4. Fastlane 설치

Ruby 업그레이드 후:

```bash
sudo gem install fastlane
```

또는 Homebrew로:

```bash
brew install fastlane
```

설치 확인:
```bash
fastlane --version
```

## 설치 후 테스트

### 빌드 테스트

```bash
make build
# 또는
./build.sh
```

### Fastlane 설정 확인

```bash
cd fastlane
fastlane lanes
```

### Fastlane 빌드 테스트 (로컬)

```bash
make build-ipa
# 또는
fastlane build_only
```

## 문제 해결

### Homebrew 설치 권한 오류

관리자 권한이 필요합니다. 터미널에서 직접 실행하거나, 시스템 설정에서 사용자 계정이 관리자 권한을 가지고 있는지 확인하세요.

### Ruby 버전이 업데이트되지 않는 경우

1. 터미널을 완전히 종료하고 다시 열기
2. `which ruby`로 현재 Ruby 경로 확인
3. PATH 설정이 올바른지 확인

### Fastlane 설치 오류

Ruby 버전이 2.7.0 이상인지 확인:
```bash
ruby --version
```

버전이 낮다면 위의 Ruby 업그레이드 단계를 다시 수행하세요.

## 다음 단계

설치가 완료되면:

1. **빌드 테스트**: `make build`
2. **Fastlane 설정 확인**: `fastlane lanes`
3. **로컬 빌드 테스트**: `make build-ipa`
4. **TestFlight 배포**: `make deploy-beta` (인증 설정 후)

## 참고

- 모든 명령어는 프로젝트 루트 디렉토리에서 실행하세요
- `make help`로 사용 가능한 명령어 목록을 확인할 수 있습니다
- 빌드 에러가 발생하면 Cursor Composer(Cmd+I)에서 "빌드 에러를 분석하고 수정해줘"라고 요청하세요
