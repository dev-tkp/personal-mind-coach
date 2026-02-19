# GitHub 저장소 연결 완료

## 연결 정보

- **저장소 URL**: https://github.com/dev-tkp/personal-mind-coach
- **Remote 이름**: origin
- **기본 브랜치**: main

## 현재 상태

✅ Git 저장소 초기화 완료  
✅ GitHub remote 연결 완료  
✅ .gitignore 파일 생성 완료  
✅ README.md 생성 완료

## 다음 단계

### 1. Git 사용자 정보 설정 (필수)

커밋하기 전에 Git 사용자 정보를 설정해야 합니다:

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

또는 전역 설정:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2. 파일 스테이징 및 커밋

```bash
# 모든 파일 추가
git add .

# 커밋
git commit -m "Initial commit: 프로젝트 초기 설정

- Xcode 프로젝트 생성
- 빌드 스크립트 및 Makefile 설정
- Fastlane 배포 설정
- SPM 가이드 및 문서 추가
- GitHub 저장소 연결"
```

### 3. GitHub에 푸시

```bash
# 첫 푸시
git push -u origin main
```

### 4. GitHub 인증 설정

만약 푸시 시 인증 오류가 발생하면:

#### Personal Access Token 사용 (권장)

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. "Generate new token" 클릭
3. 필요한 권한 선택 (repo)
4. 토큰 생성 후 복사
5. 푸시 시 비밀번호 대신 토큰 사용

#### SSH 키 사용

```bash
# SSH 키 생성 (이미 있다면 생략)
ssh-keygen -t ed25519 -C "your.email@example.com"

# 공개 키 복사
cat ~/.ssh/id_ed25519.pub

# GitHub → Settings → SSH and GPG keys → New SSH key에 추가
```

그 후 remote URL을 SSH로 변경:

```bash
git remote set-url origin git@github.com:dev-tkp/personal-mind-coach.git
```

## .gitignore 설정

다음 파일들은 Git에서 제외됩니다:

- Xcode 빌드 아티팩트 (`build/`, `DerivedData/`)
- 사용자 설정 (`xcuserdata/`)
- Fastlane API 키 (`fastlane/AuthKey_*.p8`)
- 시스템 파일 (`.DS_Store`)
- 로그 파일 (`*.log`)

## 브랜치 전략

기본 브랜치: `main`

새 기능 개발 시:

```bash
git checkout -b feature/feature-name
# 작업 후
git push -u origin feature/feature-name
```

## 유용한 Git 명령어

```bash
# 상태 확인
git status

# 변경사항 확인
git diff

# 커밋 히스토리
git log --oneline

# 원격 저장소 정보
git remote -v

# 브랜치 목록
git branch -a
```

## 문제 해결

### 푸시 권한 오류

GitHub 저장소에 대한 쓰기 권한이 있는지 확인하세요. 저장소 소유자이거나 Collaborator로 추가되어 있어야 합니다.

### 인증 오류

Personal Access Token 또는 SSH 키를 사용하여 인증하세요.

### 충돌 해결

```bash
# 최신 변경사항 가져오기
git pull origin main

# 충돌 해결 후
git add .
git commit -m "Merge conflict resolved"
git push origin main
```
