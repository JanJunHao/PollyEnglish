import SwiftUI

/// 从 YouTube 链接导入视频：粘 URL → 提交 SubtitleJob → 轮询 → 显示结果。
struct ImportYouTubeSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var urlText: String = ""
    @State private var phase: Phase = .idle
    @State private var pollingTask: Task<Void, Never>? = nil
    @State private var playerHandoff: PlayerHandoff?
    @State private var isLoadingSubtitle: Bool = false

    /// 翻译进度：nil 表示用户还没点过翻译；非 nil 时进度卡显示在 successCard 下方。
    @State private var translationPhase: TranslationPhase?
    enum TranslationPhase {
        case running
        case done(String)  // 翻译后字幕 URL
        case error(String)
    }

    enum Phase {
        case idle
        case submitting
        case running(jobId: String, since: Date)
        case done(SubtitleJob)
        case error(String)
    }

    /// 字幕下载完成后用于驱动 fullScreenCover 跳转的载荷。
    struct PlayerHandoff: Identifiable {
        let id = UUID()
        let video: DemoVideo
        let subtitle: SubtitleDocument
    }

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                header
                inputCard
                statusArea
                Spacer()
                actionButton
                legal
            }
            .padding(AppSpacing.lg)
        }
        .onDisappear { pollingTask?.cancel() }
        .fullScreenCover(item: $playerHandoff) { handoff in
            YouTubeEmbedPlayerView(video: handoff.video, preloadedSubtitle: handoff.subtitle)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("从 YouTube 导入")
                    .font(AppFonts.display(22, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("粘 URL · 服务端自动拉字幕 · 5–30 秒")
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.aiPrimary)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.bgElevated))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Input

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("YouTube 链接")
                .font(AppFonts.body(11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(AppColors.textTertiary)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "link")
                    .foregroundColor(AppColors.textTertiary)
                TextField("https://www.youtube.com/watch?v=…", text: $urlText)
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                if !urlText.isEmpty {
                    Button { urlText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))

            if let id = parsedVideoId {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("已识别：\(id)")
                        .font(AppFonts.mono(11))
                }
                .foregroundColor(AppColors.brandPrimary)
            }
        }
    }

    private var parsedVideoId: String? {
        urlText.isEmpty ? nil : YouTubeURLParser.videoId(from: urlText)
    }

    // MARK: - Status

    @ViewBuilder
    private var statusArea: some View {
        switch phase {
        case .idle:
            tipCard(
                icon: "info.circle.fill",
                color: AppColors.textTertiary,
                title: "支持 TED、TED-Ed、VOA Learning English 等带 CC-BY 协议的频道",
                detail: "粘贴标准 watch?v= / youtu.be / shorts/ 链接"
            )

        case .submitting:
            progressCard(text: "正在提交任务…")

        case .running(_, let since):
            let elapsed = Int(Date().timeIntervalSince(since))
            progressCard(text: "字幕生成中… \(elapsed)s")

        case .done(let job):
            successCard(job: job)

        case .error(let msg):
            tipCard(
                icon: "exclamationmark.triangle.fill",
                color: .red.opacity(0.85),
                title: "导入失败",
                detail: msg
            )
        }
    }

    private func progressCard(text: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            ProgressView().tint(AppColors.brandPrimary)
            Text(text)
                .font(AppFonts.body(13, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }

    private func tipCard(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }

    private func successCard(job: SubtitleJob) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.brandPrimary)
                Text("字幕生成完成")
                    .font(AppFonts.body(15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            HStack {
                statTile(label: "句数", value: job.segments_count.map(String.init) ?? "-")
                statTile(label: "Job", value: String(job.id.prefix(8)))
            }
            if let url = job.result_subtitle_url {
                Text(url)
                    .font(AppFonts.mono(10))
                    .foregroundColor(AppColors.textTertiary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }

            Button(action: { openPlayer(job: job) }) {
                HStack(spacing: 6) {
                    if isLoadingSubtitle {
                        ProgressView().tint(.black).scaleEffect(0.85)
                    } else {
                        Image(systemName: "play.fill").font(.system(size: 13, weight: .bold))
                    }
                    Text(isLoadingSubtitle ? "字幕加载中…" : startLearningTitle)
                        .font(AppFonts.body(14, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(AppColors.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
            }
            .buttonStyle(.plain)
            .disabled(isLoadingSubtitle || job.result_subtitle_url == nil)
            .padding(.top, 4)

            translationRow(job: job)
        }
        .padding(AppSpacing.md)
        .background(AppColors.brandPrimary.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: AppRadii.cardSmall).stroke(AppColors.brandPrimary.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }

    private var startLearningTitle: String {
        if case .done = translationPhase { return "开始学习（含中文）" }
        return "开始学习"
    }

    @ViewBuilder
    private func translationRow(job: SubtitleJob) -> some View {
        switch translationPhase {
        case nil:
            Button {
                runTranslation(job: job)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "character.bubble").font(.system(size: 12, weight: .semibold))
                    Text("翻译为中文 · 多等 30–60s")
                        .font(AppFonts.body(12, weight: .medium))
                }
                .foregroundColor(AppColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadii.chip)
                        .stroke(AppColors.brandPrimary.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(job.result_subtitle_url == nil)

        case .running:
            HStack(spacing: AppSpacing.sm) {
                ProgressView().tint(AppColors.brandPrimary).scaleEffect(0.8)
                Text("翻译中… gpt-4o 处理 \(job.segments_count.map(String.init) ?? "?") 句")
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
            }
            .frame(height: 32)

        case .done:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("中文翻译已就绪")
                    .font(AppFonts.body(11, weight: .medium))
                Spacer()
            }
            .foregroundColor(AppColors.brandPrimary)
            .frame(height: 32)

        case .error(let msg):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("翻译失败：\(msg)")
                    .font(AppFonts.body(11))
                    .lineLimit(2)
            }
            .foregroundColor(.red.opacity(0.85))
        }
    }

    private func runTranslation(job: SubtitleJob) {
        guard let src = job.result_subtitle_url else { return }
        translationPhase = .running
        Task { @MainActor in
            do {
                let started = try await TranslationJobsClient.shared.submit(sourceSubtitleURL: src)
                let final = try await TranslationJobsClient.shared.pollUntilDone(id: started.id)
                switch final.status {
                case .done:
                    if let url = final.result_subtitle_url {
                        translationPhase = .done(url)
                    } else {
                        translationPhase = .error("服务端没返回 result_subtitle_url")
                    }
                case .failed:
                    translationPhase = .error(final.error_message ?? "未知")
                default:
                    translationPhase = .error("意外状态：\(final.status.rawValue)")
                }
            } catch is CancellationError {
                return
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
                translationPhase = .error(msg)
            }
        }
    }

    private func openPlayer(job: SubtitleJob) {
        // 翻译完成时优先用翻译版（带中文 translation 字段），否则原版
        let urlString: String? = {
            if case .done(let translated) = translationPhase { return translated }
            return job.result_subtitle_url
        }()
        guard let urlString,
              let videoId = job.youtube_id ?? parsedVideoId
        else { return }
        isLoadingSubtitle = true
        Task { @MainActor in
            defer { isLoadingSubtitle = false }
            guard let doc = await SubtitleService.loadAsync(from: urlString) else {
                phase = .error("字幕下载失败：\(urlString)")
                return
            }
            let video = DemoVideo(
                id: "imported-\(videoId)",
                title: "YouTube 导入",
                author: "你导入的视频",
                source: "YouTube",
                durationSeconds: 0,
                cefrLevel: "—",
                thumbnailName: nil,
                categoryColorHex: 0xFFE066,
                isRecommended: false,
                categories: [],
                playMode: .youtubeEmbed,
                youtubeId: videoId
            )
            playerHandoff = PlayerHandoff(video: video, subtitle: doc)
        }
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(AppFonts.body(15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppFonts.body(10))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColors.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Action

    @ViewBuilder
    private var actionButton: some View {
        switch phase {
        case .done:
            Button {
                phase = .idle
                urlText = ""
            } label: {
                Text("再导入一个")
                    .font(AppFonts.body(15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppColors.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
            }
            .buttonStyle(.plain)

        default:
            Button(action: submit) {
                Text(submitButtonTitle)
                    .font(AppFonts.body(15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(canSubmit ? AppColors.brandPrimary : AppColors.brandPrimary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
        }
    }

    private var submitButtonTitle: String {
        switch phase {
        case .submitting: return "提交中…"
        case .running: return "生成中…"
        case .error: return "重新提交"
        default: return "生成字幕"
        }
    }

    private var canSubmit: Bool {
        guard parsedVideoId != nil else { return false }
        switch phase {
        case .submitting, .running: return false
        default: return true
        }
    }

    private var legal: some View {
        Text("仅用于学习目的。请遵守视频版权方授权范围。")
            .font(AppFonts.body(10))
            .foregroundColor(AppColors.textTertiary.opacity(0.7))
            .multilineTextAlignment(.center)
    }

    // MARK: - Submit

    private func submit() {
        guard let videoId = parsedVideoId else { return }
        pollingTask?.cancel()
        phase = .submitting
        pollingTask = Task { @MainActor in
            do {
                let job = try await SubtitleJobsClient.shared.submit(youtubeId: videoId)
                phase = .running(jobId: job.id, since: Date())
                let final = try await SubtitleJobsClient.shared.pollUntilDone(id: job.id, interval: 2, timeout: 180)
                if Task.isCancelled { return }
                switch final.status {
                case .done:
                    phase = .done(final)
                case .failed:
                    phase = .error(final.error_message ?? "服务端返回 failed")
                default:
                    phase = .error("意外状态：\(final.status.rawValue)")
                }
            } catch is CancellationError {
                return
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
                phase = .error(msg)
            }
        }
    }
}

#Preview {
    ImportYouTubeSheet()
        .preferredColorScheme(.dark)
}
