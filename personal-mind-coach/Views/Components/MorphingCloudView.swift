//
//  MorphingCloudView.swift
//  personal-mind-coach
//
//  뭉게구름 모핑 엔진: Canvas + TimelineView로 Metaball/Gooey 효과의 구름 배경
//

import SwiftUI

/// 구름 말풍선 스타일 (DesignSystem 색상 매핑)
enum CloudBubbleStyle {
    case user   // cloudUserBg
    case coach  // cloudCoachBg
}

struct MorphingCloudView: View {
    var style: CloudBubbleStyle = .coach
    var blurRadius: CGFloat = DesignSystem.Morphing.blurRadius
    var alphaThreshold: CGFloat = DesignSystem.Morphing.alphaThreshold
    var speed: Double = DesignSystem.Morphing.speed
    
    private var fillColor: Color {
        switch style {
        case .user: return Color.cloudUserBg
        case .coach: return Color.cloudCoachBg
        }
    }
    
    /// blob 개수 (성능과 질감 균형)
    private let blobCount = 6
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                // Gooey 효과: 먼저 블러로 원들이 끈적하게 합쳐지고, alphaThreshold로 경계 정리
                // 추후 플랫폼별 alphaThreshold API 확인 (max 파라미터 등)
                context.addFilter(.alphaThreshold(min: alphaThreshold, color: fillColor))
                context.addFilter(.blur(radius: blurRadius))
                
                context.drawLayer { ctx in
                    let t = timeline.date.timeIntervalSinceReferenceDate * speed
                    let centerX = size.width / 2
                    let centerY = size.height / 2
                    let radiusX = size.width * 0.45
                    let radiusY = size.height * 0.4
                    
                    for i in 0..<blobCount {
                        guard let symbol = ctx.resolveSymbol(id: i) else { continue }
                        let angle = (Double(i) / Double(blobCount)) * .pi * 2 + t * 0.3
                        let dx = sin(angle) * radiusX * 0.5 + sin(t * 0.7 + Double(i)) * 15
                        let dy = cos(angle * 0.8) * radiusY * 0.5 + cos(t * 0.5 + Double(i) * 1.2) * 12
                        let point = CGPoint(x: centerX + dx, y: centerY + dy)
                        ctx.draw(symbol, at: point, anchor: .center)
                    }
                }
            } symbols: {
                ForEach(0..<blobCount, id: \.self) { i in
                    let size = blobSize(for: i)
                    Circle()
                        .fill(Color.white)
                        .frame(width: size, height: size)
                        .tag(i)
                }
            }
        }
        .clipped()
    }
    
    /// blob별 크기 다양화 (더 자연스러운 구름)
    private func blobSize(for index: Int) -> CGFloat {
        let bases: [CGFloat] = [44, 52, 38, 48, 42, 56]
        return bases[index % bases.count]
    }
}

// MARK: - Preview (Sandbox)

struct MorphingCloudView_Previews: View {
    @State private var blurRadius: CGFloat = DesignSystem.Morphing.blurRadius
    @State private var alphaThreshold: CGFloat = DesignSystem.Morphing.alphaThreshold
    @State private var speed: Double = DesignSystem.Morphing.speed
    
    var body: some View {
        VStack(spacing: .spacingWide) {
            Text("모핑 구름 샌드박스")
                .font(.headline)
            
            MorphingCloudView(
                style: .coach,
                blurRadius: blurRadius,
                alphaThreshold: alphaThreshold,
                speed: speed
            )
            .frame(height: 120)
            .frame(maxWidth: 280)
            .clipShape(RoundedRectangle(cornerRadius: .cloudCornerRadius))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("블러 반경: \(Int(blurRadius))")
                        .font(.caption)
                    Spacer()
                }
                Slider(value: $blurRadius, in: 0...50, step: 1)
                
                HStack {
                    Text("임계값: \(String(format: "%.2f", alphaThreshold))")
                        .font(.caption)
                    Spacer()
                }
                Slider(value: $alphaThreshold, in: 0.1...0.9, step: 0.05)
                
                HStack {
                    Text("이동 속도: \(String(format: "%.2f", speed))")
                        .font(.caption)
                    Spacer()
                }
                Slider(value: $speed, in: 0.1...2.0, step: 0.1)
            }
            .padding(.horizontal)
            
            MorphingCloudView(
                style: .user,
                blurRadius: blurRadius,
                alphaThreshold: alphaThreshold,
                speed: speed
            )
            .frame(height: 100)
            .frame(maxWidth: 240)
            .clipShape(RoundedRectangle(cornerRadius: .cloudCornerRadius))
            
            Spacer()
        }
        .padding()
        .background(Color.bgMain)
    }
}

#Preview("MorphingCloudView Sandbox") {
    MorphingCloudView_Previews()
}

#Preview("MorphingCloudView Static") {
    HStack(spacing: 16) {
        MorphingCloudView(style: .user)
            .frame(width: 140, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: .cloudCornerRadius))
        MorphingCloudView(style: .coach)
            .frame(width: 180, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: .cloudCornerRadius))
    }
    .padding()
    .background(Color.bgMain)
}
