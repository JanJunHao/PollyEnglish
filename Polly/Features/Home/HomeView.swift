import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var contentService = ContentService.shared
    @StateObject private var albumService = AlbumService.shared
    @Query private var watchEvents: [WatchEvent]
    @Environment(\.scenePhase) private var scenePhase
    var switchToProfile: (() -> Void)? = nil

    @State private var presentedVideo: DemoVideo?
    @State private var presentedCategory: VideoCategory?
    @State private var presentedAlbum: Album?

    private var videos: [DemoVideo] { contentService.videos }

    /// 当前 videos 列表按分类拆桶，过滤掉空桶。
    /// VideoCategory.allCases 顺序决定模块在首页的展示顺序。
    private var nonEmptyCategories: [(id: String, category: VideoCategory, videos: [DemoVideo])] {
        VideoCategory.allCases.compactMap { cat in
            let items = videos.filter { $0.categories.contains(cat) }
            guard !items.isEmpty else { return nil }
            return (id: cat.rawValue, category: cat, videos: items)
        }
    }

    /// 首页 Banner 最多 10 条。
    /// 排序由 RecommendationService 统一打分：编辑权重 + 观看历史信号 + 微抖动。
    /// server 端 view_count / completion_rate 等强信号未来可以接到 WatchEvent 同形结构里。
    private var bannerVideos: [DemoVideo] {
        let ranked = RecommendationService.rankedVideos(videos: videos, watches: watchEvents)
        return Array(ranked.prefix(10))
    }

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    GreetingHeader()

                    if let error = contentService.lastError, !contentService.isFromServer {
                        offlineBadge(message: error)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("今日推荐")
                            .font(AppFonts.body(17, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.lg)

                        TodayBannerCard(videos: bannerVideos) { video in
                            presentedVideo = video
                        }
                    }

                    // 分类模块：空模块隐藏，至少 1 条数据才展示
                    ForEach(nonEmptyCategories, id: \.id) { entry in
                        CategorySection(
                            category: entry.category,
                            videos: entry.videos,
                            onSelect: { video in presentedVideo = video },
                            onSeeAll: { presentedCategory = entry.category }
                        )
                    }

                    if !albumService.albums.isEmpty {
                        AlbumSection(
                            albums: albumService.albums,
                            videoPool: videos,
                            onSelect: { album in presentedAlbum = album }
                        )
                    }

                    LearningPlaceholder {
                        switchToProfile?()
                    }

                    Spacer(minLength: AppSpacing.xxl)
                }
            }
            .refreshable {
                await contentService.refresh()
            }
        }
        .fullScreenCover(item: $presentedVideo) { video in
            PlayerView(video: video)
        }
        .sheet(item: $presentedCategory) { cat in
            CategoryListView(
                category: cat,
                videos: videos.filter { $0.categories.contains(cat) },
                onClose: { presentedCategory = nil }
            )
        }
        .sheet(item: $presentedAlbum) { album in
            AlbumDetailView(
                album: album,
                videos: albumService.videos(in: album, from: videos),
                onSelectVideo: { video in
                    presentedAlbum = nil
                    // 用极短延迟让 sheet dismiss 动画收掉再开 fullscreen，避免转场抖动
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        presentedVideo = video
                    }
                },
                onClose: { presentedAlbum = nil }
            )
        }
        .task {
            // 启动时永远全量拉，避免 server 端内容池变化（重新 ingest / 删除）后
            // 客户端 since 增量只能看到「新增」，看不到「下架/重排/删除」导致和服务端不一致。
            // 下拉刷新 .refreshable 同样走全量。带宽不大（~64KB / 100 条），可接受。
            await contentService.refresh()
        }
        .onAppear {
            // 开发期跳过首页直接进 Player（截图/演示用）
            if ProcessInfo.processInfo.arguments.contains("--autoplay") {
                presentedVideo = videos.first(where: { $0.isRecommended })
            }
        }
        .onChange(of: scenePhase) { _, new in
            // 从后台回前台时静默刷一次，让"后台下载完的新可用视频"自然出现，不用用户手动下拉
            if new == .active {
                Task { await contentService.refresh() }
            }
        }
    }

    private func offlineBadge(message: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 11, weight: .semibold))
            Text("使用离线内容 · 下拉重试")
                .font(AppFonts.body(11, weight: .medium))
            Spacer()
        }
        .foregroundColor(AppColors.textTertiary)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 8)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
        .padding(.horizontal, AppSpacing.lg)
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
