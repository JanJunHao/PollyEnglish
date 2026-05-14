import SwiftUI

/// 视频详情卡（顶栏 ⋯ 更多 → 视频信息）。
struct VideoDetailCard: View {
    let video: DemoVideo
    let onClose: () -> Void

    @State private var feedbackShown: Bool = false
    @State private var feedbackToast: String? = nil

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // header
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textTertiary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppColors.bgElevated))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // 缩略图大图
                        ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))

                        // 标题
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(video.title)
                                .font(AppFonts.display(22, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.leading)
                            Text("\(video.author) · \(video.source) · \(video.durationDisplay)")
                                .font(AppFonts.mono(12))
                                .foregroundColor(AppColors.textTertiary)
                        }

                        // 难度标签
                        HStack(spacing: AppSpacing.sm) {
                            metaBadge("CEFR " + video.cefrLevel, color: AppColors.aiPrimary)
                            metaBadge("AI 字幕", color: AppColors.aiPrimary)
                            metaBadge("AI 讲解", color: AppColors.brandPrimary)
                        }

                        // 学习人数 / 评分 / 难度 stats
                        statsRow

                        Divider().overlay(AppColors.textTertiary.opacity(0.2))

                        // 介绍占位
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("视频简介")
                                .font(AppFonts.body(13, weight: .semibold))
                                .foregroundColor(AppColors.textTertiary)
                                .tracking(0.5)
                            Text(introText(for: video))
                                .font(AppFonts.body(14))
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(4)
                        }

                        // 学习建议
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("学习建议")
                                .font(AppFonts.body(13, weight: .semibold))
                                .foregroundColor(AppColors.textTertiary)
                                .tracking(0.5)
                            ForEach(advice(for: video), id: \.self) { line in
                                HStack(alignment: .top, spacing: 6) {
                                    Circle().fill(AppColors.brandPrimary).frame(width: 5, height: 5)
                                        .padding(.top, 8)
                                    Text(line)
                                        .font(AppFonts.body(13))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }

                        Divider().overlay(AppColors.textTertiary.opacity(0.2))

                        // 反馈：内容不对就点这里。三个用户点同一项 → 服务端 review_pending 摘下首页。
                        feedbackSection

                        Divider().overlay(AppColors.textTertiary.opacity(0.2))

                        // 相关推荐（按分类匹配，最多 3 个）
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("相关推荐")
                                .font(AppFonts.body(13, weight: .semibold))
                                .foregroundColor(AppColors.textTertiary)
                                .tracking(0.5)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.md) {
                                    ForEach(relatedVideos) { other in
                                        relatedCard(other)
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("内容反馈")
                .font(AppFonts.body(13, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .tracking(0.5)
            Text("发现问题点一下，累积 3 票自动从首页摘下复审。")
                .font(AppFonts.body(12))
                .foregroundColor(AppColors.textTertiary)

            HStack(spacing: AppSpacing.sm) {
                feedbackChip(label: "分类不对", kind: .wrongCategory)
                feedbackChip(label: "字幕错误", kind: .wrongSubtitle)
                feedbackChip(label: "音质差", kind: .poorAudio)
            }

            if let msg = feedbackToast {
                Text(msg)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.brandPrimary)
                    .transition(.opacity)
            }
        }
    }

    private func feedbackChip(label: String, kind: ContentService.FeedbackKind) -> some View {
        Button {
            submitFeedback(kind: kind, label: label)
        } label: {
            Text(label)
                .font(AppFonts.body(12, weight: .medium))
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: AppRadii.chip)
                        .fill(AppColors.bgElevated)
                )
                .foregroundColor(AppColors.textSecondary)
        }
        .buttonStyle(.plain)
        .disabled(feedbackShown)
    }

    private func submitFeedback(kind: ContentService.FeedbackKind, label: String) {
        feedbackShown = true
        Task { @MainActor in
            let result = await ContentService.shared.submitFeedback(videoID: video.id, kind: kind)
            withAnimation {
                if let r = result {
                    feedbackToast = "已记录 · 当前 \(r.feedback_count) 票（status: \(r.status)）"
                } else {
                    feedbackToast = "发送失败 · 检查服务端"
                }
            }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation { feedbackToast = nil }
            feedbackShown = false
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: AppSpacing.md) {
            statTile(icon: "person.2.fill", value: learnerCount, label: "学习中")
            statTile(icon: "star.fill", value: ratingDisplay, label: "评分")
            statTile(icon: "bolt.fill", value: video.cefrLevel, label: "难度")
        }
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                Text(value).font(AppFonts.body(15, weight: .semibold))
            }
            .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppFonts.body(10))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }

    /// 占位：用 video.id 哈希出稳定假学习人数（demo 期；后端接入后改为真实统计）。
    private var learnerCount: String {
        let seed = video.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let count = 1200 + (seed % 8800)
        if count >= 10_000 { return String(format: "%.1f万", Double(count) / 10_000) }
        return "\(count)"
    }

    private var ratingDisplay: String {
        // 占位：4.6 - 4.9 基于 id 哈希稳定生成
        let seed = abs(video.id.hashValue)
        let raw = 4.6 + Double(seed % 30) / 100.0
        return String(format: "%.1f", raw)
    }

    private var relatedVideos: [DemoVideo] {
        ContentService.shared.videos
            .filter { $0.id != video.id && !Set($0.categories).isDisjoint(with: Set(video.categories)) }
            .prefix(3)
            .map { $0 }
    }

    private func relatedCard(_ v: DemoVideo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ThumbnailImage(name: v.thumbnailName, url: v.thumbnailURL)
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 160, height: 90)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
            Text(v.title)
                .font(AppFonts.body(12, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
            Text("\(v.durationDisplay) · \(v.cefrLevel)")
                .font(AppFonts.mono(10))
                .foregroundColor(AppColors.textTertiary)
        }
    }

    private func metaBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppFonts.mono(10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .clipShape(Capsule())
    }

    private func introText(for v: DemoVideo) -> String {
        switch v.id {
        case "julian-treasure":
            return "Julian Treasure 探索声音如何改变世界。他分享演讲的「七宗罪」和让人们真正想听你说话的方法。"
        case "ted-ed-dream":
            return "从美索不达米亚国王到古埃及人，人类几千年来一直在解释梦境。我们如何理解 dream？"
        case "tim-urban":
            return "Tim Urban 幽默地拆解拖延者大脑里的「即时满足猴子」和「理性决策者」之间的拉锯。"
        default:
            return ""
        }
    }

    private func advice(for v: DemoVideo) -> [String] {
        switch v.cefrLevel {
        case "A2", "B1":
            return ["先看 1 遍不依赖字幕", "再看 1 遍跟读浮动字幕", "长按生词出 AI 讲解"]
        default:
            return ["先看 1 遍只看英文字幕", "查不懂的词收藏到生词本", "长按精彩句子出 AI 讲解理解文化梗"]
        }
    }
}
