# 보안 이슈 해결: 노출된 API 키 제거

## 🚨 발견된 문제

GitHub에서 노출된 Google API 키가 감지되었습니다:
- **파일**: `.cursor/mind-coach-PRD.plan.md` (라인 164)
- **커밋**: `4f71c23e`
- **키**: `AIzaSyD95zh3JhAmO3wIrt-RDSX6IIQ4y_V7-q0`

## ✅ 즉시 조치 완료

1. ✅ **파일에서 API 키 제거**: `.cursor/mind-coach-PRD.plan.md`에서 실제 키를 `{YOUR_API_KEY}`로 교체
2. ✅ **보안 경고 추가**: API 키 하드코딩 금지 경고 추가

## ⚠️ 추가 조치 필요

### 1. Git 히스토리에서 API 키 제거 (중요!)

현재 커밋에서만 제거했지만, Git 히스토리에는 여전히 남아있습니다. 다음 방법 중 하나를 사용하여 완전히 제거해야 합니다:

#### 방법 1: git filter-branch 사용 (권장)

```bash
# API 키를 히스토리에서 제거
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .cursor/mind-coach-PRD.plan.md" \
  --prune-empty --tag-name-filter cat -- --all

# 강제 푸시 (주의: 팀원들에게 미리 알려야 함)
git push origin --force --all
git push origin --force --tags
```

#### 방법 2: BFG Repo-Cleaner 사용 (더 빠름)

```bash
# BFG 설치
brew install bfg

# API 키 제거
bfg --replace-text <(echo 'AIzaSyD95zh3JhAmO3wIrt-RDSX6IIQ4y_V7-q0==>REMOVED_API_KEY') personal-mind-coach.git

# 정리
cd personal-mind-coach.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 강제 푸시
git push origin --force --all
```

### 2. Google Cloud Console에서 키 폐기 및 재생성

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. API 및 서비스 > 사용자 인증 정보로 이동
3. 노출된 API 키 찾기
4. **즉시 키 삭제 또는 제한 설정**
5. 새 API 키 생성
6. 새 키를 환경변수 또는 Keychain에 저장

### 3. API 키 사용량 모니터링

노출된 키가 악용되었는지 확인:
1. Google Cloud Console에서 API 사용량 확인
2. 비정상적인 요청 패턴 확인
3. 필요시 키 즉시 폐기

## 📋 향후 예방 조치

### 1. .gitignore 업데이트

`.cursor/` 디렉토리를 .gitignore에 추가하는 것을 고려하세요:

```bash
# Cursor 설정 파일 (API 키가 포함될 수 있음)
.cursor/
```

### 2. Git Hooks 설정

pre-commit hook을 설정하여 API 키 커밋 방지:

```bash
# .git/hooks/pre-commit 파일 생성
#!/bin/bash
if git diff --cached --name-only | xargs grep -E "AIza[0-9A-Za-z_-]{35}"; then
    echo "ERROR: API 키가 감지되었습니다. 커밋을 취소합니다."
    exit 1
fi
```

### 3. GitHub Secret Scanning 활성화

GitHub 저장소 설정에서 Secret Scanning이 활성화되어 있는지 확인하세요.

## 🔐 현재 상태

- ✅ 파일에서 API 키 제거 완료
- ⏭️ Git 히스토리 정리 필요
- ⏭️ Google Cloud Console에서 키 폐기 필요
- ⏭️ 새 API 키 생성 및 설정 필요

## 참고

- 노출된 키는 이미 유출되었을 가능성이 높으므로 즉시 폐기해야 합니다
- Git 히스토리 정리는 팀원들과 협의 후 진행하세요
- 새 API 키는 환경변수 또는 Keychain에만 저장하세요
