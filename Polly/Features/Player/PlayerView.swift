import SwiftUI
import AVFoundation
import AVKit
import SwiftData
import MediaPlayer
import UIKit

struct PlayerView: View {
    let video: DemoVideo

    @StateObject private var model: PlayerModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    @State private var showControls = true
    @State private var autoHideTask: Task<Void, Never>?
    @State private var wordLookup: WordLookupResult?
    @State private var aiLookupPending: Bool = false
    @State private var explanationState: ExplanationSheetState?
    @State private var isAutoScrollEnabled: Bool = true
    @State private var bottomTab: PlayerBottomTabBar.Tab = .subtitle

    // 新增：字幕设置 / 视频详情 / 全屏 / HUD
    @StateObject private var prefs = SubtitlePreferences()
    @State private var showSubtitleSettings: Bool = false
    @State private var showVideoDetail: Bool = false
    @State private var isFullscreen: Bool = false
    @State private var sentenceFavorites: Set<Int> = []
    @State private var wasPlayingBeforeWordLookup: Bool = false
    @State private var wasPlayingBeforeExplanation: Bool = false
    @State private var showABComingSoon: Bool = false
    @State private var showShadowing: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var showFeedback: Bool = false

    // HUD（亮度/音量）
    @State private var hudKind: HUDIndicator.Kind?
    @State private var hudValue: Double = 0
    @State private var hudHideTask: Task<Void, Never>?

    @Query private var allFavorites: [SentenceFavorite]

    private let autoHideDelay: TimeInterval = 10

    init(video: DemoVideo, preloadedSubtitle: SubtitleDocument? = nil) {
        self.video = video
        let videoURL: URL = {
            // 1) 远端 URL（NASA / IA / VOA、本地导入视频走这）
            if let remote = video.videoURL, let u = URL(string: remote) {
                return u
            }
            // 2) bundle 内同名 mp4
            if let u = Bundle.main.url(forResource: video.id, withExtension: "mp4") {
                return u
            }
            // 3) 最后兜底
            return Bundle.main.url(forResource: "sample-30s", withExtension: "mp4")
                ?? URL(string: "https://download.samplelib.com/mp4/sample-30s.mp4")!
        }()
        _model = StateObject(wrappedValue: PlayerModel(
            videoURL: videoURL,
            subtitleVideoId: video.id,
            preloadedSubtitle: preloadedSubtitle
        ))
    }

    var body: some View {
        nativeBody
    }

    /// 播放器加载中：视频未就绪、或字幕仍在拉取。
    /// 加载期间统一只显示加载动画，隐藏进度条 / 播放控件 / 字幕列表。
    private var isLoading: Bool {
        !model.isReady || model.subtitleLoadState == .loading
    }

    private var nativeBody: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                videoArea
                chipsToolbar
                subtitleArea
                // 加载中不显示进度条 / 播放控件，等视频+字幕都就绪再一起出现
                if !isLoading {
                    progressArea
                        .opacity(showControls ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: showControls)
                    mainControls
                        .opacity(showControls ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: showControls)
                }
                HStack(spacing: 0) {
                    // Speed tab 改为 Menu 直接弹倍速选择
                    Menu {
                        ForEach([Float(0.5), 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { r in
                            Button {
                                model.setRate(r)
                            } label: {
                                Label(String(format: "%.2gx", r),
                                      systemImage: abs(model.playbackRate - r) < 0.01 ? "checkmark" : "")
                            }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 18, weight: .medium))
                            Text(String(format: "%.2gx", model.playbackRate))
                                .font(AppFonts.body(10))
                        }
                        .foregroundColor(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                    }

                    bottomTabButton(.loop, active: model.videoLoop)
                    bottomTabButton(.ab, active: false)
                    bottomTabButton(.subtitle, active: true)
                    bottomTabButton(.shadowing, active: false)
                }
                .frame(height: 56)
                .background(AppColors.bgPrimary)
            }
        }
        .onDisappear {
            // 返回首页时立即暂停（包括音频）
            model.pause()
            // 写入观看历史，喂首页推荐排序
            WatchHistoryTracker.record(
                videoId: video.id,
                positionSeconds: model.currentTime,
                durationSeconds: model.duration,
                in: ctx
            )
        }
        .onAppear {
            // 远端字幕优先：如果 video.subtitleURL 非空，覆盖掉 PlayerModel init 时的 bundle 字幕
            if let remote = video.subtitleURL {
                if model.subtitle == nil { model.beginSubtitleLoading() }
                Task { @MainActor in
                    if let doc = await SubtitleService.loadAsync(from: remote) {
                        model.setSubtitle(doc)
                    } else if model.subtitle == nil {
                        // 远端拉取失败且无 bundle 兜底，才算真正失败
                        model.markSubtitleFailed()
                    }
                }
            } else if model.subtitle == nil {
                // 既无远端字幕也无 bundle 字幕：确实没有字幕
                model.markSubtitleFailed()
            }

            model.togglePlay()
            scheduleAutoHide()

            // 开发期：用 --auto-lookup 启动可触发示例查词，方便 simctl 截图验证
            // 查 "you"：本地词典未收录，触发 AI fallback
            if ProcessInfo.processInfo.arguments.contains("--auto-lookup") {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    if let segs = model.subtitle?.segments {
                        for seg in segs {
                            if let voiceWord = seg.words.first(where: { $0.w.lowercased() == "voice" }) {
                                handleWordTap(word: voiceWord, in: seg)
                                // 5s 后自动加入生词本
                                try? await Task.sleep(nanoseconds: 5_000_000_000)
                                if let cur = wordLookup { addToVocabulary(cur) }
                                break
                            }
                        }
                    }
                }
            }

            // 开发期：用 --auto-explain 启动可触发 AI 讲解卡，方便 simctl 截图验证
            if ProcessInfo.processInfo.arguments.contains("--auto-explain") {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    if let firstSeg = model.subtitle?.segments.first {
                        handleSentenceLongPress(firstSeg)
                    }
                }
            }
        }
        .sheet(item: $wordLookup, onDismiss: {
            if wasPlayingBeforeWordLookup { model.play() }
            wasPlayingBeforeWordLookup = false
        }) { lookup in
            WordCard(
                lookup: lookup,
                isAIPending: aiLookupPending,
                onClose: { wordLookup = nil },
                onAddToVocab: { addToVocabulary(lookup) },
                onAIDetail: { /* 占位：触发 AI 详解 */ }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
        }
        .sheet(isPresented: $showSubtitleSettings) {
            SubtitleSettingsSheet(prefs: prefs) { showSubtitleSettings = false }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showVideoDetail) {
            VideoDetailCard(video: video) { showVideoDetail = false }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isFullscreen) {
            FullScreenPlayer(player: model.player) { isFullscreen = false }
        }
        .sheet(isPresented: $showABComingSoon) {
            ComingSoonCard(
                icon: "rectangle.split.2x1",
                title: "AB 循环",
                desc: "选定一段区间反复练习。即将上线 ✦"
            ) { showABComingSoon = false }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShadowing) {
            ShadowingSheet(
                referenceText: currentSegment?.text ?? video.title,
                referenceTranslation: currentSegment?.translation,
                onClose: { showShadowing = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [
                "我正在用 Polly 学英语：\(video.title) - \(video.author)",
                URL(string: "https://polly.app/video/\(video.id)")!
            ])
        }
        .sheet(item: $explanationState, onDismiss: {
            if wasPlayingBeforeExplanation { model.play() }
            wasPlayingBeforeExplanation = false
        }) { state in
            let cardState: ExplanationCard.State = {
                switch state.phase {
                case .loading: return .loading
                case .loaded(let r): return .loaded(r)
                case .error(let m): return .error(m)
                }
            }()
            ExplanationCard(
                sentence: state.segment.text,
                state: cardState,
                onClose: { explanationState = nil },
                onRetry: { startExplanationLoad(for: state.segment) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
        }
    }

    /// 用于 .sheet(item:) 的讲解卡状态包装。
    struct ExplanationSheetState: Identifiable {
        let id = UUID()
        let segment: SubtitleSegment
        var phase: Phase

        enum Phase {
            case loading
            case loaded(ExplanationResult)
            case error(String)
        }
    }

    // MARK: - Top Bar (设计稿 State 01：圆形按钮 + AI 字幕徽章)
    private var topBar: some View {
        HStack(spacing: AppSpacing.sm) {
            // 圆形返回按钮
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AppColors.bgElevated))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                MarqueeText(
                    text: video.title,
                    font: AppFonts.body(15, weight: .semibold),
                    foreground: AppColors.textPrimary
                )

                HStack(spacing: 6) {
                    Text("\(video.author) · \(video.source)")
                        .font(AppFonts.mono(10))
                        .foregroundColor(AppColors.textTertiary)

                    // ✦ AI 字幕 紫蓝徽章
                    HStack(spacing: 3) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 8, weight: .bold))
                        Text("AI 字幕")
                            .font(AppFonts.body(10, weight: .semibold))
                    }
                    .foregroundColor(AppColors.aiPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.aiPrimary.opacity(0.18))
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 圆形更多按钮 → 弹出菜单
            Menu {
                Button {
                    showVideoDetail = true
                } label: {
                    Label("视频信息", systemImage: "info.circle")
                }
                Button {
                    showSubtitleSettings = true
                } label: {
                    Label("字幕设置", systemImage: "textformat")
                }
                Picker("字幕语言", selection: Binding(
                    get: { prefs.language },
                    set: { prefs.language = $0 }
                )) {
                    ForEach(SubtitlePreferences.Language.allCases) { lang in
                        Text(lang.label).tag(lang)
                    }
                }
                Button {
                    showShareSheet = true
                } label: {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                Button {
                    showFeedback = true
                } label: {
                    Label("反馈", systemImage: "exclamationmark.bubble")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AppColors.bgElevated))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 54)
    }

    // MARK: - Video Area (16:9 + 圆角 + 浮动字幕 overlay + 全屏按钮 + 分区手势)
    private var videoArea: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottom) {
                Color.black
                AVPlayerLayerView(player: model.player)

                // 加载中（视频缓冲 / 字幕拉取）：转圈加载动画。
                // 画面与字幕同步——字幕区同样等加载完成才显示，避免画面还黑着字幕先冒出来。
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // 浮动字幕（视频区底部，叠加在画面上）；加载完成后才显示
                if !isLoading {
                    FloatingSubtitleView(
                        segment: currentSegment,
                        currentTime: model.currentTime,
                        prefs: prefs
                    )
                    .padding(.bottom, AppSpacing.lg)
                }

                // 分区手势层（左 -10s + 上下滑亮度 / 中央 播暂 / 右 +10s + 上下滑音量 / 单击切控件）
                VideoGestureLayer(
                    onSingleTap: {
                        // 单击只保证控件可见，不再隐藏——控件常驻
                        showControls = true
                    },
                    onDoubleTapLeft:   { model.seek(by: -10); scheduleAutoHide() },
                    onDoubleTapCenter: { model.togglePlay(); scheduleAutoHide() },
                    onDoubleTapRight:  { model.seek(by: 10); scheduleAutoHide() },
                    onBrightnessChange: { delta in adjustBrightness(by: delta) },
                    onVolumeChange:     { delta in adjustVolume(by: delta) }
                )

                // 居中 HUD（亮度/音量）
                if let kind = hudKind {
                    HUDIndicator(kind: kind, value: hudValue)
                        .transition(.opacity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // 右上角全屏按钮：用系统 AVPlayerViewController 全屏
            Button { isFullscreen = true } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(AppSpacing.sm)
        }
        .aspectRatio(16.0/9.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Chips Toolbar
    private var chipsToolbar: some View {
        ChipsToolbar(
            isAutoScrollEnabled: isAutoScrollEnabled,
            onAIExplain: {
                if let seg = currentSegment { handleSentenceLongPress(seg) }
            },
            onToggleAutoScroll: { isAutoScrollEnabled.toggle() },
            onFavorite: { /* 占位 */ },
            onVocabulary: { /* 占位 */ }
        )
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Subtitle Area
    @ViewBuilder
    private var subtitleArea: some View {
        Group {
            if !isLoading {
                SubtitleListView(
                    subtitle: model.subtitle,
                    loadState: model.subtitleLoadState,
                    currentSegmentId: model.currentSegmentId,
                    currentTime: model.currentTime,
                    favoriteIds: realFavoriteIds,
                    loopingSegmentId: model.loopSegmentId,
                    prefs: prefs,
                    onSelect: { model.seekToSegment($0) },
                    onWordTap: { word, seg in
                        handleWordTap(word: word, in: seg)
                    },
                    onLongPress: { seg in
                        handleSentenceLongPress(seg)
                    },
                    onDoubleTap: { seg in
                        model.toggleLoop(segmentId: seg.id)
                    },
                    onToggleFavorite: { seg in
                        toggleSentenceFavorite(seg)
                    }
                )
            } else {
                // 视频就绪前不显示字幕——与画面同步出现
                subtitleLoadingPlaceholder
            }
        }
        .frame(maxHeight: .infinity)
        .simultaneousGesture(pinchToZoomGesture)
    }

    private var subtitleLoadingPlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .tint(AppColors.textTertiary)
            Text("加载中…")
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 双指捏合调字幕字号：限制在 prefs 滑块同范围 [0.85, 1.4]。
    @State private var pinchBaseScale: Double = 1.0
    private var pinchToZoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let proposed = pinchBaseScale * Double(value)
                prefs.fontScale = min(max(proposed, 0.85), 1.4)
            }
            .onEnded { _ in
                pinchBaseScale = prefs.fontScale
            }
    }

    private var realFavoriteIds: Set<Int> {
        Set(allFavorites.filter { $0.videoId == video.id }.map { $0.segmentId })
    }

    // MARK: - Word Tap → 查词卡

    private func handleWordTap(word: SubtitleWord, in segment: SubtitleSegment) {
        wasPlayingBeforeWordLookup = model.isPlaying
        if model.isPlaying { model.pause() }
        let result = DictionaryService.shared.lookup(word.w, contextSentence: segment.text)
        wordLookup = result
        aiLookupPending = false

        // 未命中本地词典 → AI 实时查询（fallback）
        if result.entry == nil {
            aiLookupPending = true
            Task { @MainActor in
                do {
                    let entry = try await DictionaryService.shared.aiLookup(
                        word: result.original,
                        context: segment.text
                    )
                    // 确保还是同一个查词请求才更新（用户可能已经切到下一个词）
                    if let current = wordLookup, current.original == result.original {
                        wordLookup = WordLookupResult(
                            original: current.original,
                            lemma: current.lemma,
                            entry: entry,
                            contextSentence: current.contextSentence
                        )
                    }
                } catch {
                    // 查询失败：保持 entry nil，UI 会显示"AI 查询失败"
                    print("AI lookup failed: \(error.localizedDescription)")
                }
                aiLookupPending = false
            }
        }
    }

    // MARK: - Sentence Long Press → AI 讲解

    private func handleSentenceLongPress(_ seg: SubtitleSegment) {
        wasPlayingBeforeExplanation = model.isPlaying
        if model.isPlaying { model.pause() }
        explanationState = ExplanationSheetState(segment: seg, phase: .loading)
        startExplanationLoad(for: seg)
    }

    private func startExplanationLoad(for seg: SubtitleSegment) {
        explanationState = ExplanationSheetState(segment: seg, phase: .loading)
        Task { @MainActor in
            do {
                let r = try await ExplanationService.shared.deepExplain(segment: seg, video: video)
                if explanationState?.segment.id == seg.id {
                    explanationState?.phase = .loaded(r)
                }
            } catch {
                if explanationState?.segment.id == seg.id {
                    explanationState?.phase = .error(error.localizedDescription)
                }
            }
        }
    }

    /// 当前句（用于浮动字幕）
    private var currentSegment: SubtitleSegment? {
        guard let segs = model.subtitle?.segments,
              model.currentSegmentId >= 0,
              model.currentSegmentId < segs.count else { return nil }
        let seg = segs[model.currentSegmentId]
        // 还没到这一句的起点 → 浮动字幕保持隐藏（避免一开播放器就把第一句字幕"提前"显示出来）
        guard model.currentTime >= seg.start else { return nil }
        return seg
    }

    /// Demo 占位收藏（设计稿 State 01 第 3 句右上角有 ⭐），后续接真实生词本
    private var demoFavorites: Set<Int> { [2] }

    // MARK: - Bottom Tab Actions

    private func handleBottomTab(_ tab: PlayerBottomTabBar.Tab) {
        switch tab {
        case .speed:
            // Menu 处理
            break
        case .loop:
            model.videoLoop.toggle()
        case .ab:
            showABComingSoon = true
        case .subtitle:
            showSubtitleSettings = true
        case .shadowing:
            showShadowing = true
        }
    }

    /// 底部 Tab 通用按钮（除 speed 外）
    private func bottomTabButton(_ tab: PlayerBottomTabBar.Tab, active: Bool) -> some View {
        Button {
            handleBottomTab(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: .medium))
                Text(tab.rawValue)
                    .font(AppFonts.body(10))
            }
            .foregroundColor(active ? AppColors.brandPrimary : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sentence Favorite

    private func toggleSentenceFavorite(_ seg: SubtitleSegment) {
        if let existing = allFavorites.first(where: { $0.videoId == video.id && $0.segmentId == seg.id }) {
            ctx.delete(existing)
        } else {
            let item = SentenceFavorite(
                videoId: video.id,
                segmentId: seg.id,
                text: seg.text,
                translation: seg.translation,
                videoTitle: video.title
            )
            ctx.insert(item)
        }
        try? ctx.save()
    }

    // MARK: - Brightness / Volume

    private func adjustBrightness(by delta: Double) {
        let cur = Double(UIScreen.main.brightness)
        let next = Swift.max(0, Swift.min(1, cur + delta))
        UIScreen.main.brightness = CGFloat(next)
        showHUD(.brightness, value: next)
    }

    private func adjustVolume(by delta: Double) {
        // 系统音量改不了，但 HUD 仍显示；可用 MPVolumeView slider 间接调
        let next = Swift.max(0, Swift.min(1, hudValue + delta))
        if let slider = MPVolumeView().subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.setValue(Float(next), animated: false)
        }
        showHUD(.volume, value: next)
    }

    private func showHUD(_ kind: HUDIndicator.Kind, value: Double) {
        withAnimation(.easeOut(duration: 0.15)) {
            hudKind = kind
            hudValue = value
        }
        hudHideTask?.cancel()
        hudHideTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.2)) { hudKind = nil }
            }
        }
    }

    // MARK: - Add to Vocabulary

    private func addToVocabulary(_ lookup: WordLookupResult) {
        let meanings = lookup.entry?.definitions.map { "\($0.pos) \($0.meaning)" } ?? []
        let item = VocabularyItem(
            word: lookup.original,
            lemma: lookup.lemma,
            phonetic: lookup.entry?.phonetic,
            meanings: meanings,
            contextSentence: lookup.contextSentence,
            sourceVideoId: video.id,
            sourceVideoTitle: video.title
        )
        ctx.insert(item)
        try? ctx.save()
    }

    // MARK: - Progress (38pt)
    private var progressArea: some View {
        VStack(spacing: AppSpacing.xs) {
            ProgressBar(
                progress: model.duration > 0 ? model.currentTime / model.duration : 0,
                onSeek: { p in
                    model.seekTo(progress: p)
                    scheduleAutoHide()
                }
            )

            HStack {
                Text(formatTime(model.currentTime))
                Spacer()
                Text(formatTime(model.duration))
            }
            .font(AppFonts.mono(11))
            .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 38)
    }

    // MARK: - Main Controls (56pt)
    private var mainControls: some View {
        HStack(spacing: AppSpacing.xl) {
            ControlIconButton(systemName: "backward.end.fill") {
                model.previousSegment(); scheduleAutoHide()
            }
            ControlIconButton(systemName: "gobackward.10") {
                model.seek(by: -10); scheduleAutoHide()
            }
            PlayPauseButton(isPlaying: model.isPlaying) {
                model.togglePlay()
                if model.isPlaying { scheduleAutoHide() } else { autoHideTask?.cancel() }
            }
            ControlIconButton(systemName: "goforward.10") {
                model.seek(by: 10); scheduleAutoHide()
            }
            ControlIconButton(systemName: "forward.end.fill") {
                model.nextSegment(); scheduleAutoHide()
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Auto-hide
    private func scheduleAutoHide() {
        // 关闭自动隐藏：进度条/控件常驻可见，用户单击仍可主动 toggle。
        autoHideTask?.cancel()
    }
}

#Preview {
    PlayerView(video: DemoVideo.all[0])
        .preferredColorScheme(.dark)
}
