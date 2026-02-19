#!/bin/bash

# Fastlane 설정 테스트 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Fastlane 설정 테스트 ===${NC}\n"

# 1. Fastlane 설치 확인
echo -e "${YELLOW}1. Fastlane 설치 확인 중...${NC}"
if command -v fastlane &> /dev/null; then
    FASTLANE_VERSION=$(fastlane --version | head -n 1)
    echo -e "${GREEN}✓ Fastlane 설치됨: $FASTLANE_VERSION${NC}\n"
else
    echo -e "${RED}✗ Fastlane이 설치되어 있지 않습니다.${NC}"
    echo -e "${YELLOW}설치 방법:${NC}"
    echo -e "  brew install fastlane"
    echo -e "  또는"
    echo -e "  sudo gem install fastlane"
    echo ""
    exit 1
fi

# 2. API 키 파일 확인
echo -e "${YELLOW}2. API 키 파일 확인 중...${NC}"
API_KEY_FILE="./fastlane/AuthKey_Q53SPL7242.p8"
if [ -f "$API_KEY_FILE" ]; then
    echo -e "${GREEN}✓ API 키 파일 발견: $API_KEY_FILE${NC}"
    FILE_SIZE=$(stat -f%z "$API_KEY_FILE" 2>/dev/null || stat -c%s "$API_KEY_FILE" 2>/dev/null)
    echo -e "  파일 크기: ${FILE_SIZE} bytes"
    
    # 파일 내용 확인 (처음 몇 줄만)
    if grep -q "BEGIN PRIVATE KEY" "$API_KEY_FILE"; then
        echo -e "${GREEN}✓ 유효한 PEM 형식의 키 파일입니다.${NC}\n"
    else
        echo -e "${YELLOW}⚠ 키 파일 형식을 확인할 수 없습니다.${NC}\n"
    fi
else
    echo -e "${RED}✗ API 키 파일을 찾을 수 없습니다: $API_KEY_FILE${NC}\n"
    exit 1
fi

# 3. Fastfile 확인
echo -e "${YELLOW}3. Fastfile 확인 중...${NC}"
if [ -f "./fastlane/Fastfile" ]; then
    echo -e "${GREEN}✓ Fastfile 발견${NC}"
    
    # 주요 설정 확인
    if grep -q "PROJECT_NAME" "./fastlane/Fastfile"; then
        PROJECT_NAME=$(grep "PROJECT_NAME = " "./fastlane/Fastfile" | head -n 1 | sed 's/.*PROJECT_NAME = "\(.*\)".*/\1/')
        echo -e "  프로젝트 이름: $PROJECT_NAME"
    fi
    
    if grep -q "lane :beta" "./fastlane/Fastfile"; then
        echo -e "${GREEN}✓ beta lane 정의됨${NC}"
    fi
    
    if grep -q "lane :release" "./fastlane/Fastfile"; then
        echo -e "${GREEN}✓ release lane 정의됨${NC}"
    fi
    
    echo ""
else
    echo -e "${RED}✗ Fastfile을 찾을 수 없습니다.${NC}\n"
    exit 1
fi

# 4. Appfile 확인
echo -e "${YELLOW}4. Appfile 확인 중...${NC}"
if [ -f "./fastlane/Appfile" ]; then
    echo -e "${GREEN}✓ Appfile 발견${NC}"
    
    if grep -q "api_key_path" "./fastlane/Appfile"; then
        API_PATH=$(grep "api_key_path" "./fastlane/Appfile" | head -n 1 | sed 's/.*api_key_path("\(.*\)").*/\1/')
        echo -e "  API 키 경로: $API_PATH"
        echo -e "${GREEN}✓ API 키 경로 설정됨${NC}"
    else
        echo -e "${YELLOW}⚠ API 키 경로가 설정되지 않았습니다.${NC}"
    fi
    
    echo ""
else
    echo -e "${YELLOW}⚠ Appfile이 없습니다 (선택사항)${NC}\n"
fi

# 5. Fastlane lanes 목록 확인
echo -e "${YELLOW}5. 사용 가능한 lanes 확인 중...${NC}"
if fastlane lanes &> /dev/null; then
    echo -e "${GREEN}✓ Fastlane lanes 파싱 성공${NC}"
    echo ""
    fastlane lanes 2>/dev/null | grep -E "^\s+\w+\s+" | head -10 || echo "  (lane 목록을 가져올 수 없습니다)"
    echo ""
else
    echo -e "${YELLOW}⚠ Fastfile에 문법 오류가 있을 수 있습니다.${NC}"
    echo -e "${YELLOW}  실제 프로젝트 파일이 없어서 정확한 검증이 어렵습니다.${NC}\n"
fi

# 6. 요약
echo -e "${BLUE}=== 테스트 완료 ===${NC}\n"
echo -e "${GREEN}✓ 기본 설정이 완료되었습니다!${NC}\n"
echo -e "${YELLOW}다음 단계:${NC}"
echo -e "  1. Xcode 프로젝트 파일(.xcodeproj 또는 .xcworkspace)이 있는지 확인"
echo -e "  2. Fastfile의 PROJECT_NAME, SCHEME, WORKSPACE 값이 실제 프로젝트와 일치하는지 확인"
echo -e "  3. 배포 테스트: ${BLUE}fastlane beta${NC} 또는 ${BLUE}make deploy-beta${NC}\n"
