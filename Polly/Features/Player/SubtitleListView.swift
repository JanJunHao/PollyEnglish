import SwiftUI

struct SubtitleListView: View {
    let subtitle: SubtitleDocument?
    var loadState: PlayerModel.SubtitleLoadState = .loaded
    let currentSegmentId: Int
    let currentTime: Double
    let favoriteIds: Set<Int>
    let loopingSegmentId: Int?
    @ObservedObject var prefs: SubtitlePreferences
    let onSelect: (Int) -> Void
    let onWordTap: (SubtitleWord, SubtitleSegment) -> Void
    let onLongPress: (SubtitleSegment) -> Void
    let onDoubleTap: (SubtitleSegment) -> Void
    let onToggleFavorite: (SubtitleSegment) -> Void

    @State private var userScrolledAt: Date?
    private let manualScrollSilenceSeconds: TimeInterval = 5

    var body: some View {
        if let segments = subtitle?.segments {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        Color.clear.frame(height: 80)

                        ForEach(segments) { seg in
                            SubtitleRow(
                                segment: seg,
                                isCurrent: seg.id == currentSegmentId,
                                currentTime: currentTime,
                                isFavorite: favoriteIds.contains(seg.id),
                                isLooping: loopingSegmentId == seg.id,
                                prefs: prefs,
                                onTap: { onSelect(seg.id) },
                                onWordTap: { word in onWordTap(word, seg) },
                                onLongPress: { onLongPress(seg) },
                                onDoubleTap: { onDoubleTap(seg) },
                                onToggleFavorite: { onToggleFavorite(seg) }
                            )
                            .id(seg.id)
                        }

                        Color.clear.frame(height: 80)
                    }
                }
                .onChange(of: currentSegmentId) { _, newId in
                    if let t = userScrolledAt, Date().timeIntervalSince(t) < manualScrollSilenceSeconds {
                        return
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        proxy.scrollTo(newId, anchor: .center)
                    }
                }
            }
        } else {
            switch loadState {
            case .loading:
                SubtitleLoadingView()
            case .failed, .loaded:
                // .loaded 但 subtitle 仍为空属异常情况，按失败兜底
                SubtitleUnavailableView()
            }
        }
    }
}

// MARK: - 字幕加载中 / 失败占位

/// 字幕加载中：脉动的字幕图标 + 文案，明确告诉用户「在加载」而非「失败」。
private struct SubtitleLoadingView: View {
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "captions.bubble")
                .font(.system(size: 30, weight: .regular))
                .foregroundColor(AppColors.brandPrimary)
                .opacity(pulsing ? 1.0 : 0.3)
                .scaleEffect(pulsing ? 1.0 : 0.92)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: pulsing
                )

            Text("字幕加载中…")
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { pulsing = true }
    }
}

/// 字幕确实加载失败 / 不存在时的占位。
private struct SubtitleUnavailableView: View {
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "captions.bubble.slash")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(AppColors.textTertiary)
            Text("字幕加载失败")
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SubtitleRow

struct SubtitleRow: View {
    let segment: SubtitleSegment
    let isCurrent: Bool
    let currentTime: Double
    let isFavorite: Bool
    let isLooping: Bool
    @ObservedObject var prefs: SubtitlePreferences
    let onTap: () -> Void
    let onWordTap: (SubtitleWord) -> Void
    let onLongPress: () -> Void
    let onDoubleTap: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // 左侧 3pt 黄色发光条（仅当前句显示）
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isCurrent ? AppColors.brandPrimary : Color.clear)
                .frame(width: 3)
                .currentSentenceGlow()

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // 顶行：编号 + 时间码 + 循环图标 + ⭐
                // 双击进入/退出循环；单击跳转到此句
                HStack(spacing: AppSpacing.sm) {
                    Text(String(format: "%02d", segment.id + 1))
                        .font(AppFonts.mono(11, weight: .semibold))
                        .foregroundColor(isCurrent ? AppColors.brandPrimary : AppColors.textTertiary)

                    Text(formatTime(segment.start))
                        .font(AppFonts.mono(11))
                        .foregroundColor(AppColors.textTertiary)

                    Spacer()

                    if isLooping {
                        Image(systemName: "repeat.1")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.brandPrimary)
                    }
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(isFavorite ? AppColors.brandPrimary : AppColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { onDoubleTap() }
                .onTapGesture(count: 1) { onTap() }

                // 英文（按 prefs 决定是否显示）：每个单词是独立 Button，可点击查词
                if prefs.showEnglish {
                    FlowLayout(hSpacing: 4, vSpacing: 4) {
                        ForEach(Array(segment.words.enumerated()), id: \.offset) { _, word in
                            Button {
                                onWordTap(word)
                            } label: {
                                Text(word.w)
                                    .font(AppFonts.body(prefs.sizeEnglish, weight: isCurrent ? .medium : .regular))
                                    .foregroundColor(colorFor(word))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 中文翻译（按 prefs 决定是否显示，单击跳转 / 双击进入循环）
                if prefs.showChinese, let translation = segment.translation, !translation.isEmpty {
                    Text(translation)
                        .font(AppFonts.body(prefs.sizeChinese))
                        .foregroundColor(AppColors.subtitleChinese)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { onDoubleTap() }
                        .onTapGesture(count: 1) { onTap() }
                }
            }
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(
            isCurrent
                ? LinearGradient(
                    colors: [AppColors.brandPrimary.opacity(0.05), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                : LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing)
        )
        // 长按句子触发 AI 讲解（文档 03.8 + 04.8）
        // simultaneousGesture：与 word Button tap 共存（tap < 0.5s / long press ≥ 0.5s）
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in onLongPress() }
        )
    }

    /// 字级三态高亮：仅当前句 active；非当前句所有词都 unread。
    private func colorFor(_ word: SubtitleWord) -> Color {
        if !isCurrent { return AppColors.subtitleUnread }
        if currentTime > word.e { return AppColors.subtitleRead }
        if currentTime >= word.s { return AppColors.subtitleActive }
        return AppColors.subtitleUnread
    }
}
