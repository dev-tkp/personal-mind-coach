#!/bin/bash
# SPM (Swift Package Manager) 유틸리티 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="${PROJECT_DIR}/personal-mind-coach.xcodeproj"

# 함수: SPM 명령어 실행 (Xcode 프로젝트용)
run_spm_command() {
    local command=$1
    local description=$2
    
    echo -e "${BLUE}${description}${NC}"
    
    # Xcode 프로젝트의 경우, Package.resolved 파일이 있으면 SPM이 사용 중
    if [ -f "${PROJECT_FILE}/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
        echo -e "${YELLOW}⚠️  Xcode 프로젝트에서 SPM을 사용 중입니다.${NC}"
        echo -e "${YELLOW}   Xcode에서 다음을 실행하세요:${NC}"
        case $command in
            resolve)
                echo -e "${GREEN}   File > Packages > Resolve Package Versions${NC}"
                ;;
            update)
                echo -e "${GREEN}   File > Packages > Update to Latest Package Versions${NC}"
                ;;
            clean)
                echo -e "${GREEN}   File > Packages > Reset Package Caches${NC}"
                ;;
            show-deps)
                echo -e "${GREEN}   프로젝트 설정 > Package Dependencies 탭 확인${NC}"
                ;;
        esac
    else
        # Package.swift가 있는 경우 직접 실행
        if [ -f "${PROJECT_DIR}/Package.swift" ]; then
            cd "${PROJECT_DIR}"
            swift package $command
        else
            echo -e "${RED}❌ Package.swift 파일을 찾을 수 없습니다.${NC}"
            echo -e "${YELLOW}   Xcode 프로젝트에서 SPM 패키지를 추가하려면:${NC}"
            echo -e "${GREEN}   1. Xcode에서 프로젝트 열기${NC}"
            echo -e "${GREEN}   2. 프로젝트 설정 > Package Dependencies 탭${NC}"
            echo -e "${GREEN}   3. '+' 버튼으로 패키지 추가${NC}"
            exit 1
        fi
    fi
}

# 사용법 표시
show_usage() {
    echo -e "${BLUE}SPM (Swift Package Manager) 유틸리티${NC}"
    echo ""
    echo "사용법: $0 [명령어]"
    echo ""
    echo "명령어:"
    echo "  resolve     - 패키지 의존성 해결"
    echo "  update      - 패키지 업데이트"
    echo "  clean       - 패키지 정리"
    echo "  show-deps   - 의존성 트리 확인"
    echo "  help        - 이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0 resolve"
    echo "  $0 update"
    echo "  $0 show-deps"
}

# 메인 로직
case "${1:-help}" in
    resolve)
        run_spm_command "resolve" "📦 패키지 의존성 해결 중..."
        ;;
    update)
        run_spm_command "update" "🔄 패키지 업데이트 중..."
        ;;
    clean)
        run_spm_command "clean" "🧹 패키지 정리 중..."
        ;;
    show-deps)
        run_spm_command "show-dependencies" "🌳 패키지 의존성 트리 확인 중..."
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}❌ 알 수 없는 명령어: $1${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
