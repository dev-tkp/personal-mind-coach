//
//  DesignSystem.swift
//  personal-mind-coach
//
//  Created by 박태강 on 2/20/26.
//
//  마인드 코치 앱의 디자인 시스템
//  컨셉: Ethereal Cloud (에테리얼한 구름), Soft Fade (부드러운 페이드), Transparency (투명함)
//

import SwiftUI

// MARK: - Colors

extension Color {
    /// 사용자 구름 말풍선 배경
    /// 따뜻한 새벽 하늘 그라데이션 느낌의 부드러운 색상
    static var cloudUserBg: Color {
        Color(light: Color(red: 0.95, green: 0.92, blue: 1.0), 
              dark: Color(red: 0.35, green: 0.30, blue: 0.45))
    }
    
    /// 코치 구름 말풍선 배경
    /// 맑은 하늘 그라데이션 느낌의 깨끗하고 부드러운 색상
    static var cloudCoachBg: Color {
        Color(light: Color(red: 0.96, green: 0.98, blue: 1.0), 
              dark: Color(red: 0.25, green: 0.28, blue: 0.35))
    }
    
    /// 주요 텍스트 색상
    /// 가독성을 높이기 위한 명확한 대비를 제공하는 색상
    static var textPrimary: Color {
        Color(light: Color(red: 0.15, green: 0.15, blue: 0.2), 
              dark: Color(red: 0.95, green: 0.95, blue: 0.98))
    }
    
    /// 보조 텍스트 색상
    /// 부가 정보나 시스템 메시지에 사용되는 은은한 색상
    static var textSecondary: Color {
        Color(light: Color(red: 0.4, green: 0.4, blue: 0.45), 
              dark: Color(red: 0.65, green: 0.65, blue: 0.7))
    }
    
    /// 앱 전체 배경 색상
    /// 은은한 노이즈 질감이 느껴지는 깊이 있는 색상
    static var bgMain: Color {
        Color(light: Color(red: 0.98, green: 0.98, blue: 0.99), 
              dark: Color(red: 0.08, green: 0.08, blue: 0.12))
    }
    
    /// 브랜치 연결선 및 버튼 강조색
    /// 구름 사이를 연결하는 부드러운 강조 색상
    static var accentBranch: Color {
        Color(light: Color(red: 0.6, green: 0.7, blue: 0.95), 
              dark: Color(red: 0.5, green: 0.6, blue: 0.85))
    }
    
    /// 다크 모드 대응을 위한 편의 이니셜라이저
    private init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            switch appearance.name {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                return NSColor(dark)
            default:
                return NSColor(light)
            }
        })
        #else
        self = light
        #endif
    }
}

// MARK: - Typography

extension Font {
    /// 일반 대화 텍스트 스타일
    /// 가독성과 부드러움을 고려한 본문 폰트
    static var thoughtBody: Font {
        .system(.body, design: .rounded)
            .weight(.regular)
    }
    
    /// 시스템 메시지나 부가 정보용 캡션 스타일
    /// 작고 투명하게 표시되는 보조 텍스트
    static var thoughtCaption: Font {
        .system(.caption, design: .rounded)
            .weight(.regular)
    }
}

// MARK: - Shapes & Spacing

extension CGFloat {
    /// 구름의 둥글기를 결정하는 아주 큰 코너 반경
    /// 구름의 부드럽고 자연스러운 형태를 표현
    static var cloudCornerRadius: CGFloat { 40.0 }
    
    /// 구름의 몽환적인 느낌을 위한 블러 반경
    /// 투명하고 부드러운 구름 효과를 위한 값
    static var cloudBlurRadius: CGFloat { 8.0 }
    
    /// 표준 컴포넌트 간 여백
    /// 일관된 레이아웃을 위한 기본 간격
    static var spacingStandard: CGFloat { 16.0 }
    
    /// 넓은 컴포넌트 간 여백
    /// 섹션 간 구분이나 넓은 공간이 필요한 경우 사용
    static var spacingWide: CGFloat { 24.0 }
}

// MARK: - Animations

extension Animation {
    /// 메시지가 나타날 때 사용할 부드러운 페이드 인 + 스케일 업 애니메이션
    /// 구름이 하늘에서 부드럽게 나타나는 느낌 (뷰에 .opacity, .scaleEffect 적용 후 이 애니메이션 사용)
    static var cloudAppear: Animation {
        .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3)
    }
    
    /// 메시지가 사라질 때(Undo) 사용할 연기처럼 흩어지는 애니메이션
    /// 구름이 바람에 흩어지듯 사라지는 느낌 (transition + withAnimation(.cloudDissolve) 로 사용)
    static var cloudDissolve: Animation {
        .easeOut(duration: 0.4)
    }
}

// MARK: - Design System Constants

/// 디자인 시스템의 중앙 집중식 상수 모음
enum DesignSystem {
    /// 구름 말풍선의 기본 패딩 값
    static let cloudPadding: CGFloat = 16.0
    
    /// 구름 말풍선의 세로 패딩 값
    static let cloudVerticalPadding: CGFloat = 12.0
    
    /// 구름 말풍선의 그림자 반경
    static let cloudShadowRadius: CGFloat = 4.0
    
    /// 구름 말풍선의 그림자 투명도
    static let cloudShadowOpacity: Double = 0.08
    
    /// 구름 말풍선의 최소 높이
    static let cloudMinHeight: CGFloat = 44.0
    
    /// 구름 말풍선의 최대 너비 (화면 대비)
    static let cloudMaxWidthRatio: CGFloat = 0.75
    
    /// 브랜치 버튼의 크기
    static let branchButtonSize: CGFloat = 32.0
    
    /// 브랜치 연결선의 두께
    static let branchLineWidth: CGFloat = 2.0
    
    /// 모핑 구름 엔진 기본값 (뭉게구름 질감 확정 수치)
    enum Morphing {
        /// 블러 반경 (0~50). 낮을수록 선명한 구름 경계
        static let blurRadius: CGFloat = 7
        /// alphaThreshold (0.1~0.9). 낮을수록 부드럽게 퍼지는 구름
        static let alphaThreshold: CGFloat = 0.10
        /// 구름 조각 이동 속도 (0.1~2.0). 낮을수록 은은한 움직임
        static let speed: Double = 0.10
    }
    
    /// 애니메이션 지속 시간 (초)
    enum Duration {
        static let short: Double = 0.2
        static let standard: Double = 0.3
        static let long: Double = 0.5
    }
    
    /// 투명도 값
    enum Opacity {
        static let disabled: Double = 0.4
        static let subtle: Double = 0.6
        static let standard: Double = 0.8
        static let full: Double = 1.0
    }
}
