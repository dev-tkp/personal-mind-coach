#!/bin/bash

# iOS 프로젝트 빌드 스크립트
# 사용법: ./build.sh [scheme] [workspace/project]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 기본값 설정
SCHEME="${1:-personal-mind-coach}"
WORKSPACE="${2:-personal-mind-coach.xcworkspace}"
PROJECT="${2:-personal-mind-coach.xcodeproj}"
DESTINATION="platform=iOS Simulator,name=iPhone 16"

# xcbeautify 설치 확인
if ! command -v xcbeautify &> /dev/null; then
    echo -e "${YELLOW}경고: xcbeautify가 설치되어 있지 않습니다.${NC}"
    echo -e "${YELLOW}설치하려면: brew install xcbeautify${NC}"
    echo -e "${YELLOW}xcbeautify 없이 빌드를 계속합니다...${NC}\n"
    USE_XCBEAUTIFY=false
else
    USE_XCBEAUTIFY=true
fi

# Workspace 또는 Project 파일 확인
if [ -f "$WORKSPACE" ]; then
    echo -e "${GREEN}Workspace 파일을 찾았습니다: $WORKSPACE${NC}"
    BUILD_COMMAND="xcodebuild -scheme \"$SCHEME\" -workspace \"$WORKSPACE\" -destination '$DESTINATION' clean build"
elif [ -d "$PROJECT" ]; then
    echo -e "${GREEN}Project 파일을 찾았습니다: $PROJECT${NC}"
    BUILD_COMMAND="xcodebuild -scheme \"$SCHEME\" -project \"$PROJECT\" -destination '$DESTINATION' clean build"
else
    echo -e "${RED}에러: $WORKSPACE 또는 $PROJECT 파일을 찾을 수 없습니다.${NC}"
    echo -e "${YELLOW}사용법: ./build.sh [scheme] [workspace/project]${NC}"
    exit 1
fi

# 빌드 실행
echo -e "${GREEN}빌드를 시작합니다...${NC}\n"

if [ "$USE_XCBEAUTIFY" = true ]; then
    eval "$BUILD_COMMAND" | xcbeautify
    BUILD_EXIT_CODE=${PIPESTATUS[0]}
else
    eval "$BUILD_COMMAND"
    BUILD_EXIT_CODE=$?
fi

# 빌드 결과 확인
if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo -e "\n${GREEN}✓ 빌드 성공!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ 빌드 실패 (Exit Code: $BUILD_EXIT_CODE)${NC}"
    echo -e "${YELLOW}에러 메시지를 확인하고 Cursor AI에게 수정을 요청하세요.${NC}"
    echo -e "${YELLOW}Cursor Composer (Cmd+I)에서 '빌드 에러를 분석하고 수정해줘'라고 요청하세요.${NC}"
    exit $BUILD_EXIT_CODE
fi
