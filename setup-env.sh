#!/bin/bash
# 환경 설정 스크립트

echo "🔧 환경 설정을 시작합니다..."

# Homebrew PATH 설정 (Apple Silicon)
if [ -f "/opt/homebrew/bin/brew" ]; then
    echo "Homebrew (Apple Silicon) 경로 설정 중..."
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Homebrew PATH 설정 (Intel)
if [ -f "/usr/local/bin/brew" ]; then
    echo "Homebrew (Intel) 경로 설정 중..."
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Ruby PATH 설정 (Homebrew로 설치한 경우)
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
    echo "Ruby 경로 설정 중..."
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
fi

# rbenv 설정
if command -v rbenv &> /dev/null; then
    echo "rbenv 초기화 중..."
    eval "$(rbenv init -)"
fi

echo "✅ 환경 설정 완료!"
echo ""
echo "현재 버전:"
echo "  Ruby: $(ruby --version 2>/dev/null || echo '설치되지 않음')"
echo "  Homebrew: $(brew --version 2>/dev/null | head -1 || echo '설치되지 않음')"
echo "  Fastlane: $(fastlane --version 2>/dev/null | head -1 || echo '설치되지 않음')"
