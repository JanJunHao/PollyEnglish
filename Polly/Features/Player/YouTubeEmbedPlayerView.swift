import SwiftUI

/// TED 等 CC-NC 内容的播放器顶层视图。
/// 不 host mp4，走 YouTube iFrame 嵌入。
///
/// 当前覆盖功能：YT 视频播放 + 句级字幕跟随高亮 + 自动滚动 + 单击跳转 + ±10s + 倍速。
/// 当前未覆盖（相对原 PlayerView）：字级高亮、AI 句子讲解、单词查词卡、单句循环、字幕偏好。
/// 这些等 [YouTubeEmbedPlayer.swift] 暴露的 currentTime 精度提升 + 字级时间戳数据通路重建后补。
struct YouTubeEmbedPlayerView: View {
    let video: DemoVideo
    /// 外部预加载的字幕（ImportYouTubeSheet 跑完拿到的 SubtitleJob 结果走这里）。
    /// nil 则按 video.id 回退到 bundle 内 demo-<id>.json。
    let preloadedSubtitle: SubtitleDocument?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    @StateObject private var ytController = YouTubeEmbedController()
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isReady: Bool = false
    @State private var isPlaying: Bool = false
    @State private var errorCode: Int? = nil
    @State private var subtitle: SubtitleDocument?
    @State private var currentSegmentId: Int = 0
    @State private var manualSelectGuardUntil: Date = .distantPast
    @State private var playbackRate: Float = 1.0

    init(video: DemoVideo, preloadedSubtitle: SubtitleDocument? = nil) {
        self.video = video
        self.preloadedSubtitle = preloadedSubtitle
    }

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                videoArea
                subtitleList
                controls
            }
        }
        .onAppear {
            // 字幕来源优先级：导入流预加载 → 远端 subtitle_url → bundle demo-<id>.json
            // bundle 兜底保留是为离线场景（3 个 demo 内置字幕）。
            if let pre = preloadedSubtitle {
                self.subtitle = pre
            } else if let remote = video.subtitleURL {
                Task { @MainActor in
                    if let doc = await SubtitleService.loadAsync(from: remote) {
                        self.subtitle = doc
                    } else {
                        // 远端失败再兜底 bundle，避免 race condition 期间空白
                        self.subtitle = SubtitleService.load(videoId: video.id)
                    }
                }
            } else {
                self.subtitle = SubtitleService.load(videoId: video.id)
            }
        }
        .onDisappear {
            WatchHistoryTracker.record(
                videoId: video.id,
                positionSeconds: currentTime,
                durationSeconds: duration,
                in: ctx
            )
        }
        .onChange(of: currentTime) { _, t in
            updateCurrentSegment(t: t)
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            VStack(alignment: .center, spacing: 2) {
                Text(video.title)
                    .font(AppFonts.body(14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                Text("YouTube · \(video.source)")
                    .font(AppFonts.body(10))
                    .foregroundColor(AppColors.textTertiary)
            }
            Spacer()
            // 平衡左边 chevron 占位
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 44)
    }

    // MARK: - Video area

    private var videoArea: some View {
        ZStack {
            YouTubeEmbedPlayer(
                videoId: video.youtubeId ?? "",
                currentTime: $currentTime,
                duration: $duration,
                isReady: $isReady,
                isPlaying: $isPlaying,
                errorCode: $errorCode,
                controller: ytController
            )
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .background(Color.black)

            if let code = errorCode {
                errorOverlay(code: code)
            }
        }
    }

    /// YouTube iframe 错误友好层：把神秘错误码翻译成人话 + 给「在 YouTube 打开」逃生口。
    private func errorOverlay(code: Int) -> some View {
        let (title, hint, showOpenLink): (String, String, Bool) = {
            switch code {
            case 100:        return ("视频已被删除", "上传者已移除该视频。", false)
            case 101, 150:   return ("不允许嵌入播放", "频道方禁止外部嵌入；可在 YouTube App 中观看。", true)
            case 152:        return ("无法在此播放", "通常是地理位置限制或网络无法访问 YouTube 视频流（googlevideo.com）。请检查代理/VPN，或在 YouTube App 打开。", true)
            case 2:          return ("视频参数错误", "videoId 格式异常。", false)
            case 5:          return ("播放器错误", "HTML5 播放器加载失败，请重试。", false)
            default:         return ("无法播放（错误码 \(code)）", "请稍后重试或在 YouTube App 打开。", true)
            }
        }()
        return ZStack {
            Color.black.opacity(0.85)
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "play.slash.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.brandPrimary)
                Text(title)
                    .font(AppFonts.body(16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(hint)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                if showOpenLink, let id = video.youtubeId,
                   let url = URL(string: "https://www.youtube.com/watch?v=\(id)") {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                            Text("在 YouTube 打开")
                        }
                        .font(AppFonts.body(13, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(AppColors.brandPrimary)
                        )
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
    }

    // MARK: - Subtitle list

    private var subtitleList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.sm) {
                    if let segments = subtitle?.segments {
                        ForEach(segments) { seg in
                            subtitleRow(seg)
                                .id(seg.id)
                                .onTapGesture {
                                    manualSelectGuardUntil = Date().addingTimeInterval(0.6)
                                    currentSegmentId = seg.id
                                    ytController.seek(to: seg.start)
                                }
                        }
                    } else {
                        Text("字幕加载中…")
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.textTertiary)
                            .padding(AppSpacing.lg)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.md)
            }
            .onChange(of: currentSegmentId) { _, newId in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newId, anchor: .center)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func subtitleRow(_ seg: SubtitleSegment) -> some View {
        let isCurrent = seg.id == currentSegmentId
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Rectangle()
                .fill(isCurrent ? AppColors.brandPrimary : .clear)
                .frame(width: 3)
                .shadow(color: isCurrent ? AppColors.brandPrimary.opacity(0.6) : .clear, radius: 6)
            Text(seg.text)
                .font(AppFonts.body(15, weight: isCurrent ? .semibold : .regular))
                .foregroundColor(isCurrent ? AppColors.textPrimary : AppColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: AppRadii.chip)
                .fill(isCurrent ? AppColors.brandPrimary.opacity(0.08) : .clear)
        )
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: AppSpacing.sm) {
            // 进度条
            HStack(spacing: AppSpacing.sm) {
                Text(formatTime(currentTime))
                    .font(AppFonts.body(11).monospacedDigit())
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 38, alignment: .leading)
                Slider(
                    value: Binding(
                        get: { currentTime },
                        set: { newValue in
                            currentTime = newValue
                            ytController.seek(to: newValue)
                        }
                    ),
                    in: 0...max(duration, 1)
                )
                .tint(AppColors.brandPrimary)
                Text(formatTime(duration))
                    .font(AppFonts.body(11).monospacedDigit())
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 38, alignment: .trailing)
            }
            .padding(.horizontal, AppSpacing.lg)

            HStack(spacing: AppSpacing.xl) {
                controlButton(system: "gobackward.10") {
                    ytController.seek(to: max(0, currentTime - 10))
                }
                controlButton(system: isPlaying ? "pause.fill" : "play.fill", size: 36) {
                    if isPlaying { ytController.pause() } else { ytController.play() }
                }
                controlButton(system: "goforward.10") {
                    ytController.seek(to: min(duration, currentTime + 10))
                }

                Menu {
                    ForEach([Float(0.5), 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { r in
                        Button {
                            playbackRate = r
                            ytController.setRate(r)
                        } label: {
                            Label(String(format: "%.2gx", r),
                                  systemImage: abs(playbackRate - r) < 0.01 ? "checkmark" : "")
                        }
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 18, weight: .medium))
                        Text(String(format: "%.2gx", playbackRate))
                            .font(AppFonts.body(10))
                    }
                    .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.vertical, AppSpacing.sm)
        }
        .background(AppColors.bgPrimary)
    }

    private func controlButton(system: String, size: CGFloat = 24, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 56, height: 56)
        }
    }

    // MARK: - Helpers

    private func updateCurrentSegment(t: Double) {
        // 手动选句后留 600ms 静默，避免 seek 完成前 currentTime 抖回旧句
        guard Date() >= manualSelectGuardUntil else { return }
        guard let segments = subtitle?.segments else { return }
        if let hit = segments.first(where: { t >= $0.start && t < $0.end }),
           hit.id != currentSegmentId {
            currentSegmentId = hit.id
        }
    }

    private func formatTime(_ t: Double) -> String {
        let total = Int(t.isFinite ? t : 0)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
