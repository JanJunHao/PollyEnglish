import SwiftUI

/// 首页的分类模块行：标签 + 横滑视频卡 + 空状态。
struct CategorySection: View {
    @Environment(\.theme) private var theme
    let category: VideoCategory
    let videos: [DemoVideo]
    let onSelect: (DemoVideo) -> Void
    var onSeeAll: (() -> Void)? = nil

    /// 横滑列表最多展示 10 条，超出部分由用户划到尾部时自动跳「全部」页。
    private let displayLimit = 10

    /// 过滚动（overscroll）触发跳转的阈值：用户划到末尾后再往左多拉这么多 pt 即跳转。
    private let triggerThreshold: CGFloat = 64
    /// 回弹到这个距离以内时，重新武装触发器，避免一次跳转后反复触发。
    private let rearmThreshold: CGFloat = 16

    private let scrollSpace = "CategorySection.hscroll"

    @State private var viewportWidth: CGFloat = 0
    @State private var didTrigger = false

    private var displayedVideos: [DemoVideo] { Array(videos.prefix(displayLimit)) }

    /// 实际条数超过展示上限时，列表尾部才挂过滚动探针。
    private var hasMore: Bool { videos.count > displayLimit }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            if videos.isEmpty {
                emptyState
                    .padding(.horizontal, AppSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(displayedVideos) { video in
                            CategoryCourseCard(video: video) { onSelect(video) }
                        }
                        // 尾部探针：本身不可见，用来测量「划到末尾后的过滚动距离」
                        if hasMore {
                            overscrollProbe
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
                .coordinateSpace(name: scrollSpace)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { viewportWidth = geo.size.width }
                            .onChange(of: geo.size.width) { _, w in viewportWidth = w }
                    }
                )
                .onPreferenceChange(TrailingEdgeKey.self) { trailingMaxX in
                    handleOverscroll(trailingMaxX: trailingMaxX)
                }
            }
        }
    }

    /// 列表尾部的零宽探针：上报自身右缘在滚动坐标系中的 x。
    /// 划到末尾静止时 ≈ 视口宽；继续过滚动时该值变小，差值即过滚动距离。
    private var overscrollProbe: some View {
        Color.clear
            .frame(width: 1)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: TrailingEdgeKey.self,
                        value: geo.frame(in: .named(scrollSpace)).maxX
                    )
                }
            )
    }

    /// 过滚动到阈值时自动跳「全部」页；回弹后重新武装，保证一次手势只跳一次。
    private func handleOverscroll(trailingMaxX: CGFloat) {
        guard hasMore, viewportWidth > 0 else { return }
        let overscroll = viewportWidth - trailingMaxX
        if overscroll <= rearmThreshold {
            didTrigger = false
        } else if overscroll >= triggerThreshold, !didTrigger {
            didTrigger = true
            onSeeAll?()
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            // 模块色 icon 胶囊
            HStack(spacing: 5) {
                Image(systemName: category.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(category.displayName)
                    .font(AppFonts.body(13, weight: .semibold))
            }
            .foregroundColor(category.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(category.accentColor.opacity(0.15))
            )

            Spacer()

            if !videos.isEmpty, let onSeeAll {
                Button(action: onSeeAll) {
                    HStack(spacing: 2) {
                        Text("查看全部")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .font(AppFonts.body(11))
                    .foregroundColor(theme.textTer)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var emptyState: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: category.icon)
                .font(.system(size: 18))
                .foregroundColor(category.accentColor.opacity(0.6))
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(category.accentColor.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("内容准备中")
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(theme.textSec)
                Text("即将自动归类到该模块")
                    .font(AppFonts.body(11))
                    .foregroundColor(theme.textTer)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .background(theme.surfaceElev)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }
}

private struct CategoryCourseCard: View {
    @Environment(\.theme) private var theme
    let video: DemoVideo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 100)
                        .clipped()
                    Circle()
                        .fill(video.categoryColor)
                        .frame(width: 8, height: 8)
                        .padding(AppSpacing.sm)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(AppFonts.body(13, weight: .medium))
                        .foregroundColor(theme.text)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(video.durationDisplay) · \(video.cefrLevel)")
                        .font(AppFonts.mono(10))
                        .foregroundColor(theme.textTer)
                }
                .padding(AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 180)
            .background(theme.surfaceElev)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        }
        .buttonStyle(.plain)
    }
}

/// 上报横滑列表尾部探针右缘在滚动坐标系中的 x 坐标，用于检测过滚动。
private struct TrailingEdgeKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
