import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var contentService = ContentService.shared
    @StateObject private var albumService = AlbumService.shared
    @Query private var watchEvents: [WatchEvent]
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.theme) private var theme
    var switchToProfile: (() -> Void)? = nil

    @State private var presentedVideo: DemoVideo?
    @State private var presentedCategory: VideoCategory?
    @State private var presentedAlbum: Album?
    @State private var offlineErrorDetail: String?
    // 默认 tab；开发期可用启动参数 --tab-foreign / --tab-recent 直接定位（截图/演示用，同 --autoplay）。
    @State private var discoverTab: DiscoverTab = {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--tab-foreign") { return .foreign }
        if args.contains("--tab-recent")  { return .recent }
        return .recommend
    }()

    private var videos: [DemoVideo] { contentService.videos }

    /// 当前 videos 列表按分类拆桶，过滤掉空桶。
    /// VideoCategory.allCases 顺序决定模块在首页的展示顺序。
    /// 每个视频只归入唯一的「主分类」，避免同一视频在多个模块里重复出现。
    private var nonEmptyCategories: [(id: String, category: VideoCategory, videos: [DemoVideo])] {
        VideoCategory.allCases.compactMap { cat in
            let items = videos.filter { primaryCategory(of: $0) == cat }
            guard !items.isEmpty else { return nil }
            return (id: cat.rawValue, category: cat, videos: items)
        }
    }

    /// 视频的主分类：按 VideoCategory.allCases 顺序取首个命中的分类。
    /// 一个视频可挂多个 categories，但首页只在主分类下展示一次。
    private func primaryCategory(of video: DemoVideo) -> VideoCategory? {
        VideoCategory.allCases.first { video.categories.contains($0) }
    }

    /// 推荐排序结果。由 RecommendationService 统一打分：编辑权重 + 观看历史信号 + 微抖动。
    /// server 端 view_count / completion_rate 等强信号未来可以接到 WatchEvent 同形结构里。
    private var rankedVideos: [DemoVideo] {
        RecommendationService.rankedVideos(videos: videos, watches: watchEvents)
    }

    /// 首页 Banner 最多 5 条。
    private var bannerVideos: [DemoVideo] { Array(rankedVideos.prefix(5)) }

    /// 热门推荐排行榜 3 条。
    private var trendingVideos: [DemoVideo] { Array(rankedVideos.prefix(3)) }

    /// 热门精选横滑卡。
    private var featuredVideos: [DemoVideo] { rankedVideos }

    /// 视频数最多的分类，给「查看更多」临时用（LibraryView 见 README §五，未实现）。
    private var largestCategory: VideoCategory? {
        nonEmptyCategories.max { $0.videos.count < $1.videos.count }?.category
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            // 顶部 CategoryTabs 固定不滚动；下方内容区随 tab 整块替换（设计交付 v2 §2.1）。
            VStack(spacing: 0) {
                CategoryTabs(selection: $discoverTab)
                tabContent
            }
        }
        .fullScreenCover(item: $presentedVideo) { video in
            PlayerView(video: video)
        }
        .sheet(item: $presentedCategory) { cat in
            CategoryListView(
                category: cat,
                videos: videos.filter { primaryCategory(of: $0) == cat },
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
        .alert("无法连接服务器", isPresented: .constant(offlineErrorDetail != nil), presenting: offlineErrorDetail) { _ in
            Button("好") { offlineErrorDetail = nil }
        } message: { detail in
            Text(detail)
        }
    }

    // MARK: - Tab 内容分发

    @ViewBuilder
    private var tabContent: some View {
        switch discoverTab {
        case .recommend: recommendTab
        case .foreign:   ArticleFeed()
        case .recent:    RecentFeed(onOpenVideo: { presentedVideo = $0 })
        }
    }

    /// 推荐 tab（设计交付 v2 §2.2）：Banner 轮播 + 热门推荐 + 热门精选。
    /// 每日收听 / 最新上架 / 主题探索见 Phase 2b。
    @ViewBuilder
    private var recommendTab: some View {
        if videos.isEmpty {
            // 加载中 / 网络异常占位：占满内容区并垂直居中
            emptyStateView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if let error = contentService.lastError, !contentService.isFromServer {
                            offlineBadge(message: error)
                                .padding(.top, AppSpacing.md)
                        }

                        TodayBannerCard(videos: bannerVideos) { video in
                            presentedVideo = video
                        }
                        .padding(.top, AppSpacing.md)

                        TrendingSection(
                            videos: trendingVideos,
                            onSelect: { presentedVideo = $0 },
                            onSeeAll: seeAllLibrary
                        )

                        FeaturedSection(
                            videos: featuredVideos,
                            onSelect: { presentedVideo = $0 },
                            onSeeAll: seeAllLibrary
                        )

                        if let daily = rankedVideos.first {
                            DailyListeningSection(video: daily) {
                                presentedVideo = daily
                            }
                            .id("daily")
                        }

                        NewArrivalSection(
                            videos: featuredVideos,
                            onSelect: { presentedVideo = $0 },
                            onSeeAll: seeAllLibrary
                        )

                        TopicSection()
                            .id("topics")

                        Spacer(minLength: 100)
                    }
                }
                .refreshable {
                    await contentService.refresh()
                }
                .onChange(of: videos.isEmpty) { _, isEmpty in
                    // 开发期：启动参数 --scroll-daily / --scroll-topics 自动滚到对应 section（截图用）。
                    guard !isEmpty else { return }
                    let args = ProcessInfo.processInfo.arguments
                    let target = args.contains("--scroll-topics") ? "topics"
                               : args.contains("--scroll-daily") ? "daily" : nil
                    guard let target else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation { proxy.scrollTo(target, anchor: .top) }
                    }
                }
            }
        }
    }

    /// 「查看更多」临时跳到视频数最多的分类列表（LibraryView 实现后改接到课程库）。
    private func seeAllLibrary() {
        presentedCategory = largestCategory
    }

    /// 尚未实现的 tab 占位（外刊 / 最近更新，Phase 3 / 4 实现）。
    private func comingSoon(_ name: String, systemImage: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .regular))
                .foregroundColor(theme.textTer)
            Text("\(name)即将上线")
                .font(AppFonts.body(15, weight: .semibold))
                .foregroundColor(theme.text)
            Text("正在打磨中，敬请期待")
                .font(AppFonts.body(12))
                .foregroundColor(theme.textTer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if let error = contentService.lastError {
            networkErrorPlaceholder(message: error)
        } else {
            loadingPlaceholder
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .tint(theme.textTer)
            Text("加载中…")
                .font(AppFonts.body(13))
                .foregroundColor(theme.textTer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func networkErrorPlaceholder(message: String) -> some View {
        let serverURL = (Bundle.main.object(forInfoDictionaryKey: "PollyServerURL") as? String) ?? "—"
        return VStack(spacing: AppSpacing.lg) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 56, weight: .regular))
                .foregroundColor(theme.textTer)

            VStack(spacing: AppSpacing.sm) {
                Text("网络异常")
                    .font(AppFonts.body(17, weight: .semibold))
                    .foregroundColor(theme.text)
                Text("无法连接到服务器，请检查网络后重试")
                    .font(AppFonts.body(13))
                    .foregroundColor(theme.textSec)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await contentService.refresh() }
            } label: {
                Text("重试")
                    .font(AppFonts.body(14, weight: .semibold))
                    .foregroundColor(theme.text)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.sm + 2)
                    .background(theme.surfaceElev)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
            }
            .buttonStyle(.plain)

            Button {
                offlineErrorDetail = "\(message)\n\nServer: \(serverURL)"
            } label: {
                Text("查看详情")
                    .font(AppFonts.body(12))
                    .foregroundColor(theme.textTer)
                    .underline()
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppSpacing.lg)
    }

    private func offlineBadge(message: String) -> some View {
        let serverURL = (Bundle.main.object(forInfoDictionaryKey: "PollyServerURL") as? String) ?? "—"
        // DEBUG 模式直接显示错误首行，方便真机联调时分辨「网断了」还是「就是只有 3 条」。
        // Release 保留简短文案，避免给用户看到 raw error。
        #if DEBUG
        let label = "离线内容 · \(message.split(separator: "\n").first.map(String.init) ?? message)"
        #else
        let label = "使用离线内容 · 下拉重试"
        #endif
        return Button {
            offlineErrorDetail = "\(message)\n\nServer: \(serverURL)"
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(AppFonts.body(11, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "info.circle")
                    .font(.system(size: 11, weight: .regular))
            }
            .foregroundColor(theme.textTer)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 8)
            .background(theme.surfaceElev)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.lg)
    }
}

#Preview {
    HomeView()
}
