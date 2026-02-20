# 마인드 코치 앱 UI 화면 명세서
## Figma AI 디자인 가이드

**디자인 컨셉:** Ethereal Cloud (에테리얼한 구름), Soft Fade (부드러운 페이드), Transparency (투명함)

---

## 1. Main Chat View (메인 채팅 화면)

### 1.1 전체 레이아웃 구조

```
┌─────────────────────────────────────────┐
│ Safe Area Top                           │
├─────────────────────────────────────────┤
│ Navigation Bar (Height: 44pt)           │ ← bgMain 배경
│   [설정 아이콘] [마인드 코치] [삭제]     │
├─────────────────────────────────────────┤
│                                         │
│ Scrollable Content Area                 │ ← bgMain 배경
│   (LazyVStack, 역순 스크롤)             │
│                                         │
│   ┌─────────────────────────────┐       │
│   │ AI Message Bubble (좌측)    │       │
│   │   [더 물어보기 버튼]         │       │
│   └─────────────────────────────┘       │
│                                         │
│              ┌─────────────────┐        │
│              │ User Bubble (우측)│      │
│              └─────────────────┘        │
│                                         │
│   ┌─────────────────────────────┐       │
│   │ AI Message Bubble (좌측)    │       │
│   └─────────────────────────────┘       │
│                                         │
├─────────────────────────────────────────┤
│ Branch Indicator Bar (Height: 40pt)    │ ← bgMain 배경, accentBranch 테두리
│   [← 메인으로] (조건부 표시)            │
├─────────────────────────────────────────┤
│ Input Bar (Height: 56pt)                │ ← bgMain 배경
│   [입력창]              [전송 버튼]      │
├─────────────────────────────────────────┤
│ Safe Area Bottom                        │
└─────────────────────────────────────────┘
```

### 1.2 Navigation Bar 상세

**위치:**
- Top: Safe Area Top (0pt)
- Height: 44pt
- Left/Right: 0pt (전체 너비)

**컴포넌트 배치:**
- **왼쪽 버튼 (설정):**
  - Left: `spacingStandard` (16pt)
  - Size: 24pt × 24pt
  - Color: `textSecondary`
  - Icon: SF Symbol "gearshape" 또는 "slider.horizontal.3"

- **중앙 타이틀:**
  - Center: 화면 중앙
  - Font: `.thoughtBody` (17pt, rounded)
  - Color: `textPrimary`
  - Text: "마인드 코치"

- **오른쪽 버튼 (삭제):**
  - Right: `spacingStandard` (16pt)
  - Size: 24pt × 24pt
  - Color: `textSecondary`
  - Icon: SF Symbol "trash" 또는 "ellipsis"

**배경:**
- Color: `bgMain`
- Opacity: `DesignSystem.Opacity.full` (1.0)

### 1.3 Scrollable Content Area 상세

**위치:**
- Top: Navigation Bar 하단 (0pt 간격)
- Bottom: Branch Indicator Bar 상단 (0pt 간격)
- Left/Right: 0pt (전체 너비)
- Padding: `spacingStandard` (16pt) 좌우

**배경:**
- Color: `bgMain`

**스크롤 방향:**
- Vertical (위에서 아래로, 최신 메시지가 하단)
- LazyVStack 사용 (성능 최적화)

### 1.4 AI Message Bubble (코치 구름 말풍선)

**위치:**
- Alignment: Leading (좌측 정렬)
- Left Margin: 0pt
- Right Margin: 화면 너비의 `cloudMaxWidthRatio` (75%)까지 확장 가능
- Top/Bottom Spacing: `spacingStandard` (16pt)

**크기:**
- Min Height: `cloudMinHeight` (44pt)
- Max Width: 화면 너비 × `cloudMaxWidthRatio` (0.75)
- Padding Horizontal: `cloudPadding` (16pt)
- Padding Vertical: `cloudVerticalPadding` (12pt)

**스타일:**
- Background Color: `cloudCoachBg`
- Text Color: `textPrimary`
- Font: `.thoughtBody` (17pt, rounded, regular)
- Corner Radius: `cloudCornerRadius` (40pt) - 매우 둥근 구름 형태
- Shadow:
  - Radius: `cloudShadowRadius` (4pt)
  - Opacity: `cloudShadowOpacity` (0.08)
  - Offset: (0, 2pt)
  - Color: Black

**블러 효과 (선택적):**
- Background Blur: `cloudBlurRadius` (8pt)
- Opacity: `DesignSystem.Opacity.subtle` (0.6) - 투명한 구름 느낌

**내부 구조:**
```
┌─────────────────────────────────┐
│ [메시지 텍스트]                  │ ← thoughtBody 폰트
│                                 │
│ [더 물어보기 버튼] (하단)        │ ← BranchButton
│                                 │
│ [시간] (우측 하단)               │ ← thoughtCaption, textSecondary
└─────────────────────────────────┘
```

### 1.5 User Message Bubble (사용자 구름 말풍선)

**위치:**
- Alignment: Trailing (우측 정렬)
- Right Margin: 0pt
- Left Margin: 화면 너비의 `cloudMaxWidthRatio` (75%)까지 확장 가능
- Top/Bottom Spacing: `spacingStandard` (16pt)

**크기:**
- Min Height: `cloudMinHeight` (44pt)
- Max Width: 화면 너비 × `cloudMaxWidthRatio` (0.75)
- Padding Horizontal: `cloudPadding` (16pt)
- Padding Vertical: `cloudVerticalPadding` (12pt)

**스타일:**
- Background Color: `cloudUserBg` (따뜻한 새벽 하늘 톤)
- Text Color: `textPrimary`
- Font: `.thoughtBody` (17pt, rounded, regular)
- Corner Radius: `cloudCornerRadius` (40pt)
- Shadow:
  - Radius: `cloudShadowRadius` (4pt)
  - Opacity: `cloudShadowOpacity` (0.08)
  - Offset: (0, 2pt)
  - Color: Black

**내부 구조:**
```
              ┌─────────────────┐
              │ [메시지 텍스트]  │ ← thoughtBody 폰트
              │                 │
              │ [시간] (좌측 하단)│ ← thoughtCaption, textSecondary
              └─────────────────┘
```

### 1.6 Branch Button (더 물어보기 버튼)

**위치:**
- AI Message Bubble 하단
- Top Margin: 4pt (버블과의 간격)
- Left Alignment: AI Message Bubble과 동일한 좌측 정렬

**크기:**
- Width: `branchButtonSize` (32pt)
- Height: `branchButtonSize` (32pt)

**스타일:**
- Background Color: `accentBranch`
- Icon Color: White 또는 `textPrimary` (대비 고려)
- Corner Radius: 16pt (원형에 가까움)
- Opacity: `DesignSystem.Opacity.full` (1.0)
- Shadow:
  - Radius: 2pt
  - Opacity: 0.1
  - Offset: (0, 1pt)

**아이콘:**
- SF Symbol: "plus.circle" 또는 "arrow.branch"
- Size: 16pt

**인터랙션:**
- Tap: 브랜치 질문 모드 활성화
- Hover/Press: Opacity `DesignSystem.Opacity.subtle` (0.6)로 변경

### 1.7 Branch Indicator Bar (브랜치 경로 표시)

**위치:**
- Top: Scrollable Content Area 하단
- Height: 40pt
- Left/Right: 0pt (전체 너비)

**표시 조건:**
- 현재 브랜치가 메인 줄기가 아닐 때만 표시

**스타일:**
- Background Color: `bgMain`
- Border Top: `branchLineWidth` (2pt), Color: `accentBranch`
- Padding Horizontal: `spacingStandard` (16pt)
- Padding Vertical: 8pt

**내부 컴포넌트:**
- **뒤로가기 버튼:**
  - Left: `spacingStandard` (16pt)
  - Icon: SF Symbol "arrow.left"
  - Size: 20pt × 20pt
  - Color: `accentBranch`
  - Text: "메인으로" (옵션)
  - Font: `.thoughtCaption` (12pt, rounded)

**브랜치 경로 표시 (선택적):**
- 현재 브랜치 경로를 점선 또는 아이콘으로 표시
- Color: `textSecondary`
- Font: `.thoughtCaption`

### 1.8 Message Input Bar (입력창)

**위치:**
- Top: Branch Indicator Bar 하단 (또는 Scrollable Content Area 하단)
- Height: 56pt
- Left/Right: 0pt (전체 너비)
- Bottom: Safe Area Bottom

**배경:**
- Color: `bgMain`
- Border Top: 1pt, Color: `textSecondary` (Opacity: 0.2)

**내부 레이아웃:**
```
┌─────────────────────────────────────────┐
│ [spacingStandard] [입력창] [8pt] [전송] │
└─────────────────────────────────────────┘
```

**입력창 (TextField):**
- Left Margin: `spacingStandard` (16pt)
- Right Margin: 8pt (전송 버튼과의 간격)
- Height: 40pt
- Background Color: `cloudCoachBg` (약간 투명하게)
- Corner Radius: 20pt (둥근 형태)
- Padding Horizontal: `spacingStandard` (16pt)
- Padding Vertical: 10pt
- Font: `.thoughtBody` (17pt, rounded)
- Text Color: `textPrimary`
- Placeholder Color: `textSecondary` (Opacity: 0.6)
- Placeholder Text: "메시지를 입력하세요..."

**전송 버튼:**
- Right Margin: `spacingStandard` (16pt)
- Size: 40pt × 40pt
- Background Color: `accentBranch`
- Icon: SF Symbol "arrow.up.circle.fill"
- Icon Size: 24pt
- Icon Color: White
- Corner Radius: 20pt (원형)
- Shadow:
  - Radius: 2pt
  - Opacity: 0.15
  - Offset: (0, 1pt)

**비활성 상태:**
- Opacity: `DesignSystem.Opacity.disabled` (0.4)
- 인터랙션 비활성화

---

## 2. Branching UI (브랜치 시각화)

### 2.1 브랜치 구조 시각화

**개념:**
- 메인 줄기: 세로로 내려오는 메시지 체인
- 브랜치: 특정 메시지에서 갈라져 나오는 새 줄기
- 연결선: 부모 메시지와 자식 메시지를 연결하는 시각적 선

### 2.2 메인 줄기 메시지

**위치:**
- 좌측 정렬 (AI) 또는 우측 정렬 (User)
- 들여쓰기 없음

**스타일:**
- 기본 Message Bubble과 동일
- Background: `cloudCoachBg` (AI) 또는 `cloudUserBg` (User)

### 2.3 브랜치 메시지 (들여쓰기)

**위치:**
- 부모 메시지에서 오른쪽으로 들여쓰기
- 들여쓰기 값: `spacingWide` (24pt) × 브랜치 깊이

**예시 (브랜치 깊이 1):**
```
┌─────────────────────────────┐
│ AI Message (메인)           │ ← 좌측 정렬
└─────────────────────────────┘
    │
    ├─ [spacingWide] ─┐
                      │
                      ┌─────────────────┐
                      │ User Branch     │ ← 들여쓰기 24pt
                      └─────────────────┘
```

**예시 (브랜치 깊이 2):**
```
                      ┌─────────────────┐
                      │ User Branch 1   │ ← 들여쓰기 24pt
                      └─────────────────┘
                          │
                          ├─ [spacingWide] ─┐
                                            │
                                            ┌─────────────┐
                                            │ AI Branch 2 │ ← 들여쓰기 48pt
                                            └─────────────┘
```

### 2.4 브랜치 연결선 (Branch Line)

**위치:**
- 부모 메시지의 우측 하단 모서리에서 시작
- 자식 메시지의 좌측 상단 모서리로 연결

**스타일:**
- Stroke Width: `branchLineWidth` (2pt)
- Color: `accentBranch`
- Opacity: `DesignSystem.Opacity.subtle` (0.6)
- Line Cap: Round
- Line Join: Round

**경로:**
```
부모 메시지 우측 하단
    │
    ├─ 수평선 (spacingWide 길이)
    │
    └─ 수직선 (메시지 간격만큼)
        │
        └─ 자식 메시지 좌측 상단
```

**구현 예시:**
- Path 또는 Shape로 그리기
- Z-index: 메시지 버블보다 낮게 (배경 레이어)

### 2.5 브랜치 깊이 시각화

**깊이별 색상 변화 (선택적):**
- 깊이 1: `accentBranch` (기본)
- 깊이 2: `accentBranch` (Opacity: 0.8)
- 깊이 3+: `accentBranch` (Opacity: 0.6)

**깊이별 들여쓰기:**
- 깊이 N: `spacingWide` (24pt) × N

### 2.6 브랜치 버튼 위치 (브랜치 생성 시)

**브랜치 모드 활성화 시:**
- 입력창 상단에 부모 메시지 미리보기 표시
- 배경: `cloudCoachBg` (Opacity: 0.5)
- 텍스트: "이 메시지에 대해 더 물어보기"
- Font: `.thoughtCaption`
- Color: `textSecondary`

---

## 3. Background Summary (Floating) - 백그라운드 정보 표시

### 3.1 Floating Summary Card

**위치:**
- 화면 우측 상단 (Navigation Bar 하단)
- Top: Navigation Bar 하단 + `spacingStandard` (16pt)
- Right: `spacingStandard` (16pt)
- Width: 화면 너비의 30-40% (최대 200pt)
- Position: Fixed (스크롤과 무관하게 고정)

**표시 조건:**
- 백그라운드 정보가 존재할 때만 표시
- 사용자가 요청 시 숨김/표시 토글 가능

### 3.2 Card 구조

```
┌─────────────────────────┐
│ [접기 버튼] (우측 상단)  │
├─────────────────────────┤
│ "AI가 기억하는 정보"     │ ← thoughtCaption, textSecondary
├─────────────────────────┤
│ [요약 텍스트]            │ ← thoughtCaption, textPrimary
│ (최대 3-4줄, 말줄임)    │
└─────────────────────────┘
```

### 3.3 스타일 상세

**배경:**
- Background Color: `cloudCoachBg`
- Opacity: `DesignSystem.Opacity.standard` (0.8) - 반투명 구름 느낌
- Corner Radius: `cloudCornerRadius` (40pt) - 구름 형태
- Border: 1pt, Color: `accentBranch` (Opacity: 0.3)

**그림자:**
- Radius: `cloudShadowRadius` (4pt)
- Opacity: `cloudShadowOpacity` (0.08)
- Offset: (0, 2pt)

**블러 효과:**
- Background Blur: `cloudBlurRadius` (8pt)
- 투명하고 부드러운 구름 느낌

**패딩:**
- Horizontal: `cloudPadding` (16pt)
- Vertical: `cloudVerticalPadding` (12pt)

### 3.4 내부 컴포넌트

**헤더:**
- Text: "AI가 기억하는 정보"
- Font: `.thoughtCaption` (12pt, rounded)
- Color: `textSecondary`
- Top Margin: 0pt
- Bottom Margin: 8pt

**요약 텍스트:**
- Font: `.thoughtCaption` (12pt, rounded)
- Color: `textPrimary`
- Line Height: 1.4
- Max Lines: 4
- Line Break: Truncate Tail

**접기 버튼:**
- Position: 우측 상단
- Size: 24pt × 24pt
- Icon: SF Symbol "xmark.circle.fill" 또는 "chevron.up"
- Color: `textSecondary`
- Opacity: `DesignSystem.Opacity.subtle` (0.6)

### 3.5 애니메이션

**표시/숨김:**
- Animation: `.cloudAppear` (페이드 인 + 스케일 업)
- Duration: `DesignSystem.Duration.standard` (0.3초)

**업데이트 시:**
- Animation: `.cloudAppear` (부드러운 전환)
- Duration: `DesignSystem.Duration.short` (0.2초)

### 3.6 확장 상태 (선택적)

**탭 시 확장:**
- 전체 화면 모달 또는 하단 시트로 표시
- 배경: `bgMain`
- 전체 요약 텍스트 표시
- Font: `.thoughtBody`
- Scrollable

---

## 4. 디자인 시스템 변수 매핑 요약

### 4.1 색상 (Colors)

| 컴포넌트 | 변수명 | 용도 |
|---------|--------|------|
| 사용자 말풍선 배경 | `cloudUserBg` | 사용자 메시지 배경색 |
| 코치 말풍선 배경 | `cloudCoachBg` | AI 메시지 배경색 |
| 주요 텍스트 | `textPrimary` | 본문 텍스트 색상 |
| 보조 텍스트 | `textSecondary` | 캡션, 시간, 플레이스홀더 |
| 앱 배경 | `bgMain` | 전체 화면 배경 |
| 브랜치 강조 | `accentBranch` | 브랜치 버튼, 연결선, 전송 버튼 |

### 4.2 타이포그래피 (Typography)

| 컴포넌트 | 변수명 | 크기 | 용도 |
|---------|--------|------|------|
| 본문 텍스트 | `.thoughtBody` | 17pt | 메시지 내용 |
| 캡션 텍스트 | `.thoughtCaption` | 12pt | 시간, 시스템 메시지, 요약 |

### 4.3 간격 (Spacing)

| 컴포넌트 | 변수명 | 값 | 용도 |
|---------|--------|-----|------|
| 표준 간격 | `spacingStandard` | 16pt | 기본 여백, 패딩 |
| 넓은 간격 | `spacingWide` | 24pt | 브랜치 들여쓰기, 섹션 간격 |

### 4.4 형태 (Shapes)

| 컴포넌트 | 변수명 | 값 | 용도 |
|---------|--------|-----|------|
| 구름 코너 반경 | `cloudCornerRadius` | 40pt | 말풍선 둥글기 |
| 블러 반경 | `cloudBlurRadius` | 8pt | 구름 블러 효과 |
| 그림자 반경 | `cloudShadowRadius` | 4pt | 말풍선 그림자 |
| 그림자 투명도 | `cloudShadowOpacity` | 0.08 | 그림자 강도 |

### 4.5 크기 (Sizes)

| 컴포넌트 | 변수명 | 값 | 용도 |
|---------|--------|-----|------|
| 말풍선 최소 높이 | `cloudMinHeight` | 44pt | 최소 터치 영역 |
| 말풍선 최대 너비 비율 | `cloudMaxWidthRatio` | 0.75 | 화면 대비 너비 |
| 브랜치 버튼 크기 | `branchButtonSize` | 32pt | 버튼 크기 |
| 브랜치 연결선 두께 | `branchLineWidth` | 2pt | 연결선 굵기 |

### 4.6 투명도 (Opacity)

| 컴포넌트 | 변수명 | 값 | 용도 |
|---------|--------|-----|------|
| 비활성 | `DesignSystem.Opacity.disabled` | 0.4 | 비활성 버튼 |
| 은은함 | `DesignSystem.Opacity.subtle` | 0.6 | 보조 요소 |
| 표준 | `DesignSystem.Opacity.standard` | 0.8 | 플로팅 카드 |
| 완전 | `DesignSystem.Opacity.full` | 1.0 | 기본 요소 |

### 4.7 애니메이션 (Animations)

| 컴포넌트 | 변수명 | 용도 |
|---------|--------|------|
| 나타남 | `.cloudAppear` | 메시지 표시, 카드 표시 |
| 사라짐 | `.cloudDissolve` | 메시지 삭제, Undo |

---

## 5. Figma AI 프롬프트 (한 줄 요약)

### 5.1 Main Chat View

**프롬프트:**
```
Create an iOS chat interface with ethereal cloud-style message bubbles: left-aligned AI bubbles (cloudCoachBg background, 40pt corner radius, 16pt padding) and right-aligned user bubbles (cloudUserBg background). Use bgMain for screen background, thoughtBody font (17pt rounded) for messages, spacingStandard (16pt) for gaps. Add a bottom input bar (56pt height) with rounded text field and accentBranch send button. Navigation bar (44pt) at top with gear icon left, "마인드 코치" center title, trash icon right. All bubbles have soft shadows (4pt radius, 0.08 opacity) and optional 8pt blur for ethereal cloud effect.
```

### 5.2 Branching UI

**프롬프트:**
```
Design a branching conversation UI: main thread messages aligned left/right, branch messages indented by spacingWide (24pt) per depth level. Connect parent and child messages with accentBranch colored lines (2pt width, 0.6 opacity, rounded caps). Branch button (32pt circle, accentBranch background) appears below AI messages. Show branch indicator bar (40pt height) at bottom when not on main thread, with "← 메인으로" button. Use visual depth cues: deeper branches have lighter accentBranch opacity (0.8 for depth 2, 0.6 for depth 3+).
```

### 5.3 Background Summary (Floating)

**프롬프트:**
```
Create a floating summary card (30-40% screen width, max 200pt) positioned top-right below navigation bar. Use cloudCoachBg background with 0.8 opacity, 40pt corner radius, 8pt blur for ethereal cloud effect. Include header "AI가 기억하는 정보" (thoughtCaption, textSecondary) and summary text (thoughtCaption, textPrimary, max 4 lines truncated). Add close button (24pt) top-right. Soft shadow (4pt radius, 0.08 opacity) and subtle accentBranch border (1pt, 0.3 opacity). Padding: 16pt horizontal, 12pt vertical. Animate appearance with fade-in and scale-up.
```

---

## 6. 추가 디자인 가이드라인

### 6.1 다크 모드 대응

- 모든 색상은 자동으로 다크 모드 색상으로 전환됨
- `Color(light:dark:)` 이니셜라이저 사용
- 다크 모드에서도 구름의 부드러운 느낌 유지

### 6.2 접근성 (Accessibility)

- 최소 터치 영역: 44pt × 44pt
- 텍스트 대비 비율: WCAG AA 기준 준수
- VoiceOver 레이블: 모든 인터랙티브 요소에 추가
- Dynamic Type 지원: `.thoughtBody`, `.thoughtCaption` 사용

### 6.3 애니메이션 타이밍

- 짧은 애니메이션: `DesignSystem.Duration.short` (0.2초)
- 표준 애니메이션: `DesignSystem.Duration.standard` (0.3초)
- 긴 애니메이션: `DesignSystem.Duration.long` (0.5초)

### 6.4 반응형 레이아웃

- iPhone SE (375pt): 모든 요소 정상 표시
- iPhone Pro Max (428pt): 여유 공간 활용
- iPad (768pt+): 최대 너비 제한 (예: 600pt 중앙 정렬)

---

**문서 버전:** 1.0  
**최종 업데이트:** 2026-02-20  
**작성 기준:** DesignSystem.swift v1.0, PRD v1.0
