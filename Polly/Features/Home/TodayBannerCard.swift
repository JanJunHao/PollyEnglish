import SwiftUI

struct TodayBannerCard: View {
    let videos: [DemoVideo]
    let action: (DemoVideo) -> Void

    @State private var currentIndex: Int = 0
    @State private var isDragging: Bool = false

    // 虚拟数组无限循环：10 个 banner × 10 = 100 个虚拟项，起始放中间，左右各 50 步，
    // 远超用户实际滑动。multiplier 越大越占内存（TabView 不 lazy），保守 10 够用。
    private let virtualMultiplier = 10
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    private var totalCount: Int { videos.count * virtualMultiplier }

    /// 把 virtual index 映射回 [0, videos.count) 真实 index。
    private var realIndex: Int {
        guard videos.count > 0 else { return 0 }
        return ((currentIndex % videos.count) + videos.count) % videos.count
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            TabView(selection: $currentIndex) {
                ForEach(0..<totalCount, id: \.self) { i in
                    let v = videos[((i % videos.count) + videos.count) % videos.count]
                    BannerSlide(video: v) { action(v) }
                        .padding(.horizontal, AppSpacing.lg)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)
            // 让手势进入时暂停自动滚动
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in isDragging = true }
                    .onEnded { _ in isDragging = false }
            )

            PageIndicator(count: videos.count, current: realIndex)
        }
        .onAppear {
            if videos.count > 1 {
                // 起始放在虚拟数组的中央，左右滑都不会到头
                currentIndex = videos.count * (virtualMultiplier / 2)
            }
        }
        .onReceive(timer) { _ in
            guard !isDragging, videos.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                currentIndex += 1
            }
        }
    }
}

// MARK: - 单张 Banner 视图

private struct BannerSlide: View {
    let video: DemoVideo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()

                // 底部黑色渐变蒙版（蒙住 50% 高度）
                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 130)
                .frame(maxWidth: .infinity, alignment: .bottom)

                HStack(alignment: .bottom, spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(video.title)
                            .font(AppFonts.body(18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text("\(video.durationDisplay) · \(video.cefrLevel) 中级 · \(video.source)")
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    PlayCircleButton()
                }
                .padding(AppSpacing.lg)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.card))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 分页指示点

private struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AppColors.brandPrimary : Color.white.opacity(0.25))
                    .frame(width: i == current ? 18 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: current)
            }
        }
    }
}

private struct PlayCircleButton: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.brandPrimary)
                .frame(width: 56, height: 56)

            Image(systemName: "play.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
                .offset(x: 2)
        }
        .shadow(color: AppColors.brandPrimary.opacity(0.3), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    TodayBannerCard(videos: DemoVideo.all) { _ in }
        .preferredColorScheme(.dark)
        .background(AppColors.bgPrimary)
}
