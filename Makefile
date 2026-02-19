.PHONY: build clean install-deps help deploy-beta deploy-release build-ipa fastlane-init spm-resolve spm-update spm-clean spm-show-deps

# 기본 설정 (프로젝트에 맞게 수정하세요)
SCHEME ?= personal-mind-coach
WORKSPACE ?= personal-mind-coach.xcworkspace
PROJECT ?= personal-mind-coach.xcodeproj
DESTINATION ?= "platform=iOS Simulator,name=iPhone 16"

help: ## 사용 가능한 명령어 목록 표시
	@echo "사용 가능한 명령어:"
	@echo ""
	@echo "빌드:"
	@echo "  make build          - 프로젝트 빌드"
	@echo "  make clean          - 빌드 캐시 정리"
	@echo "  make install-deps   - xcbeautify 설치"
	@echo ""
	@echo "SPM (Swift Package Manager):"
	@echo "  make spm-resolve    - SPM 패키지 의존성 해결"
	@echo "  make spm-update     - SPM 패키지 업데이트"
	@echo "  make spm-clean      - SPM 패키지 정리"
	@echo "  make spm-show-deps - SPM 패키지 의존성 트리 확인"
	@echo ""
	@echo "배포 (Fastlane):"
	@echo "  make deploy-beta    - TestFlight에 베타 배포"
	@echo "  make deploy-release - App Store에 프로덕션 배포"
	@echo "  make build-ipa      - 로컬에만 빌드 (업로드 없음)"
	@echo "  make fastlane-init  - Fastlane 초기화"
	@echo ""
	@echo "환경 변수:"
	@echo "  SCHEME=YourScheme make build"
	@echo "  WORKSPACE=YourProject.xcworkspace make build"

install-deps: ## xcbeautify 및 Fastlane 설치
	@echo "xcbeautify 설치 중..."
	@brew install xcbeautify || echo "brew가 설치되어 있지 않거나 xcbeautify 설치에 실패했습니다."
	@echo ""
	@echo "Fastlane 설치 중..."
	@brew install fastlane || echo "Fastlane 설치에 실패했습니다. 'sudo gem install fastlane'을 시도해보세요."

build: ## 프로젝트 빌드
	@./build.sh $(SCHEME) $(WORKSPACE) || ./build.sh $(SCHEME) $(PROJECT)

clean: ## 빌드 캐시 정리
	@echo "빌드 캐시 정리 중..."
	@rm -rf ~/Library/Developer/Xcode/DerivedData/*
	@echo "완료!"

# Fastlane 배포 명령어
deploy-beta: ## TestFlight에 베타 배포
	@echo "🚀 TestFlight에 베타 배포를 시작합니다..."
	@fastlane beta

deploy-release: ## App Store에 프로덕션 배포
	@echo "🚀 App Store에 프로덕션 배포를 시작합니다..."
	@fastlane release

build-ipa: ## 로컬에만 빌드 (업로드 없음)
	@echo "📦 로컬 빌드를 시작합니다..."
	@fastlane build_only

fastlane-init: ## Fastlane 초기화
	@echo "🔧 Fastlane을 초기화합니다..."
	@fastlane init

# SPM (Swift Package Manager) 명령어
spm-resolve: ## SPM 패키지 의존성 해결
	@echo "📦 SPM 패키지 의존성을 해결합니다..."
	@cd $(PROJECT) && swift package resolve 2>/dev/null || echo "⚠️  Xcode 프로젝트에서 직접 관리하는 경우, Xcode에서 File > Packages > Resolve Package Versions를 사용하세요."

spm-update: ## SPM 패키지 업데이트
	@echo "🔄 SPM 패키지를 업데이트합니다..."
	@cd $(PROJECT) && swift package update 2>/dev/null || echo "⚠️  Xcode 프로젝트에서 직접 관리하는 경우, Xcode에서 File > Packages > Update to Latest Package Versions를 사용하세요."

spm-clean: ## SPM 패키지 정리
	@echo "🧹 SPM 패키지를 정리합니다..."
	@cd $(PROJECT) && swift package clean 2>/dev/null || echo "⚠️  Xcode 프로젝트에서 직접 관리하는 경우, Xcode에서 File > Packages > Reset Package Caches를 사용하세요."

spm-show-deps: ## SPM 패키지 의존성 트리 확인
	@echo "🌳 SPM 패키지 의존성 트리:"
	@cd $(PROJECT) && swift package show-dependencies 2>/dev/null || echo "⚠️  Xcode 프로젝트에서 직접 관리하는 경우, Xcode에서 프로젝트 설정 > Package Dependencies를 확인하세요."
