import SwiftUI

/// 首页推荐 Banner 轮播（设计交付 v2 §2.2 A）。
/// 用 TabView .page 实现——翻页天然互斥，卡片绝不会重叠；
/// 配合「虚拟数组」做无缝无限循环：currentIndex 一路递增，靠近边界时静默回中。
/// 自动轮播 5.2s 一次。
struct TodayBannerCard: View {
    let videos: [DemoVideo]
    let action: (DemoVideo) -> Void

    @State private var currentIndex: Int = 0
    private let timer = Timer.publish(every: 5.2, on: .main, in: .common).autoconnect()

    // 虚拟数组：videos 重复 virtualMultiplier 份，起点放正中，左右都滑不到头。
    private let virtualMultiplier = 12

    private var totalCount: Int { videos.count * virtualMultiplier }

    private func realIndex(_ i: Int) -> Int {
        guard !videos.isEmpty else { return 0 }
        return ((i % videos.count) + videos.count) % videos.count
    }

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(0..<totalCount, id: \.self) { i in
                let real = realIndex(i)
                BannerSlide(video: videos[real], index: real, total: videos.count) {
                    action(videos[real])
                }
                .padding(.horizontal, 16)
                .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 234)
        .onAppear {
            if videos.count > 1, currentIndex == 0 {
                currentIndex = videos.count * (virtualMultiplier / 2)
            }
        }
        .onReceive(timer) { _ in
            guard videos.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.55)) {
                currentIndex += 1
            }
        }
        .onChange(of: currentIndex) { _, _ in
            recenterIfNeeded()
        }
    }

    /// currentIndex 漂到虚拟数组边缘时，无动画跳回正中的等价位置——
    /// 展示的真实卡片不变，用户无感，避免滑到数组尽头。
    private func recenterIfNeeded() {
        guard videos.count > 1 else { return }
        let margin = videos.count
        guard currentIndex < margin || currentIndex > totalCount - margin else { return }
        let mid = videos.count * (virtualMultiplier / 2)
        currentIndex = mid + realIndex(currentIndex)
    }
}

// MARK: - 单张 Banner

private struct BannerSlide: View {
    let video: DemoVideo
    let index: Int
    let total: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // 封面永远保持深色（README §2.2）：不随主题翻色，像 YouTube 缩略图。
                ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 234)
                    .frame(maxWidth: .infinity)
                    .clipped()

                // 底部 60% 高度黑色渐变蒙版
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.55), location: 0.55),
                        .init(color: .black.opacity(0.92), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 234 * 0.6)
                .frame(maxWidth: .infinity, alignment: .bottom)
                .allowsHitTesting(false)

                HStack(alignment: .bottom, spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: 6) {
                        // banner 文字恒为浅色（封面恒深）
                        Text(video.title)
                            .font(AppFonts.body(16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .shadow(color: .black.opacity(0.5), radius: 8, y: 2)

                        Text("\(video.author.uppercased()) · \(video.durationDisplay) · \(video.cefrLevel)")
                            .font(AppFonts.mono(10.5))
                            .foregroundColor(.white.opacity(0.7))

                        // 进度 dots：active 14×4 胶囊，inactive 4×4
                        HStack(spacing: 4) {
                            ForEach(0..<max(total, 1), id: \.self) { d in
                                Capsule()
                                    .fill(.white.opacity(d == index ? 1 : 0.4))
                                    .frame(width: d == index ? 14 : 4, height: 4)
                                    .animation(.easeInOut(duration: 0.3), value: index)
                            }
                        }
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    BannerPlayButton()
                }
                .padding(14)
            }
            .frame(height: 234)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}

/// Banner 右下角 52pt 黄色圆形播放按钮。
private struct BannerPlayButton: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.brand)
                .frame(width: 52, height: 52)
            Image(systemName: "play.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .offset(x: 2)
        }
        .shadow(color: theme.brand.opacity(0.4), radius: 22, x: 0, y: 6)
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)
    }
}
