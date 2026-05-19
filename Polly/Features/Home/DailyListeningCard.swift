import SwiftUI

/// 每日收听 Section（设计交付 v2 §2.2 D）。
struct DailyListeningSection: View {
    let video: DemoVideo
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "每日收听")
            DailyListeningCard(video: video, onSelect: onSelect)
                .padding(.horizontal, 14)
        }
    }
}

/// 每日收听海报卡。**两个模式都保持深色** —— 像海报，故不走 theme 翻色。
private struct DailyListeningCard: View {
    @Environment(\.theme) private var theme
    let video: DemoVideo
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // 56pt 黄色圆形播放按钮
                ZStack {
                    Circle()
                        .fill(theme.brand)
                        .frame(width: 56, height: 56)
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                        .offset(x: 3)
                }
                .shadow(color: theme.brand.opacity(0.4), radius: 16, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("DAY 7")
                            .font(AppFonts.mono(9.5, weight: .bold))
                            .foregroundColor(theme.brand)
                            .tracking(1)
                        Text("· 以商业英语为主")
                            .font(AppFonts.mono(9.5))
                            .foregroundColor(.white.opacity(0.42))
                    }
                    Text("Today's pick")
                        .font(AppFonts.display(18, weight: .medium).italic())
                        .foregroundColor(.white)
                    Text(video.title)
                        .font(AppFonts.body(13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("\(video.durationDisplay) · \(video.cefrLevel)")
                        .font(AppFonts.mono(10))
                        .foregroundColor(.white.opacity(0.62))
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16))
            .background(alignment: .trailing) {
                WaveformDecoration(color: theme.brand)
                    .opacity(0.18)
                    .frame(width: 130)
                    .allowsHitTesting(false)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x161620), Color(hex: 0x0A0A0C)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

/// 右侧装饰性波形条：20 条不同高度的纵向矩形。
private struct WaveformDecoration: View {
    let color: Color
    private let heights: [CGFloat] = [20,55,35,80,45,70,30,90,50,40,75,25,60,42,85,30,50,38,72,28]

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 3) {
                ForEach(Array(heights.enumerated()), id: \.offset) { _, h in
                    Capsule()
                        .fill(color)
                        .frame(width: 3, height: geo.size.height * (h / 90))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
    }
}
