# 마인드 코치 앱 — 디자인 파일 목록 & UI 현황

**목적:** Gemini 디자인 리뷰용. 디자인 관련 코드 목록과 현재 UI 구현 상태를 한 문서에서 파악할 수 있도록 정리함.

**디자인 컨셉:** Ethereal Cloud (에테리얼한 구름), Soft Fade (부드러운 페이드), Transparency (투명함)

---

## 1. 디자인 관련 파일 목록

### 1.1 디자인 시스템 (단일 진입점)

| 파일 경로 | 설명 |
|-----------|------|
| `personal-mind-coach/DesignSystem.swift` | 색상(Color), 폰트(Font), 간격/형태(CGFloat), 애니메이션(Animation), 상수(DesignSystem enum) 정의. 다크 모드 대응 색상, 모핑 구름 기본값(Morphing) 포함. |

### 1.2 UI 명세서 (참고용, 코드 아님)

| 파일 경로 | 설명 |
|-----------|------|
| `UI_SPECIFICATION.md` | Figma AI용 화면 명세. Main Chat View, Branching UI, Background Summary(Floating) 레이아웃·컴포넌트·디자인 변수 매핑. |

### 1.3 뷰 및 컴포넌트 (SwiftUI)

| 파일 경로 | 역할 | DesignSystem 연동 |
|-----------|------|-------------------|
| `personal-mind-coach/Views/ChatView.swift` | 메인 채팅 화면. 메시지 리스트(CloudBubbleView), BranchIndicator, MessageInputBar, UndoToast, 네비게이션·툴바. | 배경 미적용(bgMain 미사용). 리스트 간격 16, CloudBubbleView/애니메이션 연동. |
| `personal-mind-coach/Views/Components/MorphingCloudView.swift` | 모핑 구름 엔진. Canvas + TimelineView, alphaThreshold + blur, cloudUserBg/cloudCoachBg. | DesignSystem.Morphing(blurRadius 7, alphaThreshold 0.10, speed 0.10), Color 확장 사용. |
| `personal-mind-coach/Views/Components/CloudBubbleView.swift` | 말풍선 UI. MorphingCloudView 배경 + 메시지 텍스트 + 브랜치 버튼(코치만). | thoughtBody, textPrimary, thoughtCaption, textSecondary, cloudPadding, cloudVerticalPadding, cloudMinHeight, cloudMaxWidthRatio, cloudCornerRadius, cloudShadow*, branchButtonSize, accentBranch, cloudAppear, cloudDissolve. |
| `personal-mind-coach/Views/MessageInputBar.swift` | 하단 입력 바. TextField + 전송 버튼. | 미적용. 시스템 배경·회색/파란색 사용. |
| `personal-mind-coach/Views/BranchIndicator.swift` | 브랜치 시 “메인으로 돌아가기” 바. | 미적용. systemGray6, .blue, .secondary 사용. |
| `personal-mind-coach/Views/UndoToast.swift` | 삭제 후 “실행 취소” 토스트. | 미적용. 검정 0.85, 흰색 텍스트, 12pt corner. |
| `personal-mind-coach/Views/BranchButton.swift` | “여기서 더 물어보기” 버튼(텍스트+아이콘). | 미적용. CloudBubbleView 내부에서는 별도 버튼 UI(accentBranch 원형) 사용. BranchButton은 현재 ChatView에서 직접 쓰이지 않음. |
| `personal-mind-coach/Views/MessageBubble.swift` | 구형 말풍선(단색 배경). | 미적용. ChatView는 CloudBubbleView 사용 중. 참고/폴백용으로 파일만 존재. |
| `personal-mind-coach/Views/Chat/ChatViewDraft.swift` | CloudBubbleView만 쓰는 샘플 리스트(목업). | 샘플 메시지 4개, CloudBubbleView·spacingStandard·bgMain 사용. |
| `personal-mind-coach/ContentView.swift` | 기본 “Hello, world!” 플레이스홀더. | 미사용. 앱 진입은 ChatView. |

---

## 2. DesignSystem.swift 요약 (Gemini 리뷰용)

### 2.1 Colors (Color extension, 다크 모드 대응)

- `cloudUserBg` — 사용자 구름 말풍선 배경 (따뜻한 새벽 하늘 톤)
- `cloudCoachBg` — 코치 구름 말풍선 배경 (맑은 하늘 톤)
- `textPrimary` — 본문 텍스트
- `textSecondary` — 보조 텍스트·캡션
- `bgMain` — 앱 전체 배경
- `accentBranch` — 브랜치 버튼·연결선 강조

### 2.2 Typography (Font extension)

- `thoughtBody` — 본문 (system body, rounded, regular)
- `thoughtCaption` — 캡션 (system caption, rounded, regular)

### 2.3 Shapes & Spacing (CGFloat)

- `cloudCornerRadius` — 40
- `cloudBlurRadius` — 8 (별도; 모핑은 DesignSystem.Morphing 사용)
- `spacingStandard` — 16
- `spacingWide` — 24

### 2.4 Animations (Animation extension)

- `cloudAppear` — spring(response: 0.5, dampingFraction: 0.7) — 메시지 등장
- `cloudDissolve` — easeOut(duration: 0.4) — 메시지 삭제/Undo

### 2.5 DesignSystem enum 상수

- `cloudPadding` 16, `cloudVerticalPadding` 12  
- `cloudShadowRadius` 4, `cloudShadowOpacity` 0.08  
- `cloudMinHeight` 44, `cloudMaxWidthRatio` 0.75  
- `branchButtonSize` 32, `branchLineWidth` 2  
- `DesignSystem.Morphing`: `blurRadius` 7, `alphaThreshold` 0.10, `speed` 0.10  
- `Duration`: short 0.2, standard 0.3, long 0.5  
- `Opacity`: disabled 0.4, subtle 0.6, standard 0.8, full 1.0  

---

## 3. 현재 UI 현황

### 3.1 메인 채팅 화면 (ChatView)

- **구성:** NavigationStack → ZStack(VStack: BranchIndicator(조건부) → ScrollView(메시지 리스트) → Divider → MessageInputBar) + UndoToast(조건부).
- **메시지 리스트:** LazyVStack, `ForEach(messages)` → HStack(Spacer, CloudBubbleView, Spacer)로 좌/우 정렬. 빈 상태일 때 안내 문구 + 아이콘. 로딩 시 ProgressView + “응답 중...”.
- **말풍선:** 전부 **CloudBubbleView** (MorphingCloudView 배경, thoughtBody/textPrimary, 코치일 때만 하단 accentBranch 원형 “더 물어보기” 버튼). 등장: cloudAppear, 삭제: cloudDissolve + transition.
- **DesignSystem 미적용:** 전체 배경(bgMain), 네비게이션 바·툴바 색상, 빈 상태/로딩 텍스트 폰트·색상(secondary 등 시스템 기본).

### 3.2 브랜치 UI

- **BranchIndicator:** 메인 아닐 때 상단에 “메인으로 돌아가기” + “브랜치: N개 메시지”. DesignSystem 미적용(시스템 컬러).
- **브랜치 버튼:** CloudBubbleView 내부에 DesignSystem(branchButtonSize, accentBranch) 적용된 원형 버튼. “여기서 더 물어보기” 시 브랜치 입력 모드.
- **브랜치 연결선:** UI 명세의 `branchLineWidth`·시각적 갈래는 아직 구현되지 않음(데이터만 parent_id 기반).

### 3.3 입력 바 (MessageInputBar)

- TextField + 전송(arrow.up.circle.fill). DesignSystem 미적용. 시스템 배경·회색/파란색.

### 3.4 Undo 토스트 (UndoToast)

- 삭제 후 하단 토스트 “메시지가 삭제되었습니다” + “실행 취소”. DesignSystem 미적용. 검정 0.85, 흰색.

### 3.5 기타

- **Background Summary (Floating):** UI_SPECIFICATION에만 명세 있음. 코드 없음.
- **설정/삭제 툴바:** 툴바에 설정(gearshape)만 있고, 색상은 .blue 등 시스템. 삭제 버튼은 명세에 있으나 현재 툴바에는 없음.

---

## 4. 명세 대비 갭 (디자인 리뷰 시 참고)

| 명세 항목 | 현재 구현 |
|-----------|-----------|
| bgMain 전체 배경 | 미적용 (ChatView, ScrollView, InputBar, BranchIndicator 배경 미지정 또는 시스템) |
| Navigation Bar 색상·폰트 | 시스템 기본. thoughtBody, textPrimary, textSecondary 미적용. |
| MessageInputBar | DesignSystem 미적용. cloudCoachBg·thoughtBody·accentBranch 등 명세 미반영. |
| BranchIndicator | DesignSystem 미적용. bgMain, accentBranch 테두리, thoughtCaption 등 미반영. |
| UndoToast | DesignSystem 미반영. 스타일만 단독 정의. |
| 브랜치 연결선(branchLineWidth) | 미구현. |
| Background Summary (Floating) | 미구현. |
| 빈 상태/로딩 텍스트 | thoughtBody/thoughtCaption, textSecondary 미적용. |

---

## 5. Gemini 디자인 리뷰 시 체크 포인트

1. **일관성:** DesignSystem이 정의된 색·폰트·간격이 채팅 말풍선(CloudBubbleView)에는 잘 적용되어 있음. 나머지 화면(헤더, 입력 바, 브랜치 바, 토스트)은 시스템 기본 또는 단독 스타일 사용.
2. **컨셉 반영:** “구름·투명·부드러움”은 말풍선(모핑 구름 + cloudAppear/cloudDissolve)에만 강하게 반영됨. 배경·입력 바·브랜치 바까지 확장하면 컨셉이 더 통일됨.
3. **접근성·다국어:** CloudBubbleView 등에 accessibilityLabel/Hint, String(localized:) 사용. 다른 뷰는 일부만 적용.
4. **명세 충실도:** `UI_SPECIFICATION.md`의 Main Chat View 레이아웃·변수 매핑은 CloudBubbleView/메시지 리스트에 대체로 반영. 입력 바·브랜치 바·배경·Floating Summary는 미반영 또는 미구현.

---

**문서 버전:** 1.0  
**기준:** DesignSystem.swift, 현재 브랜치 UI/채팅 구현 상태.  
**다음 단계:** Gemini에 이 문서와 필요 시 `DesignSystem.swift`, `UI_SPECIFICATION.md`, `CloudBubbleView.swift`, `ChatView.swift` 일부를 함께 제공하면 디자인 리뷰에 활용하기 좋음.
