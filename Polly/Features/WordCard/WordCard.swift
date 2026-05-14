import SwiftUI

/// 查词卡（设计稿规格 + 文档 03.16 字段）。
/// 从底部弹出，最小高度档展示主要释义；用户可上拉看更多。
struct WordCard: View {
    let lookup: WordLookupResult
    let isAIPending: Bool
    let onClose: () -> Void
    let onAddToVocab: () -> Void
    let onAIDetail: () -> Void

    @State private var addedToVocab = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header

            if let entry = lookup.entry {
                phoneticAndLevel(entry: entry)
                definitions(entry: entry)
                if let ctx = lookup.contextSentence, !ctx.isEmpty {
                    contextExample(ctx)
                }
                ctaButtons
            } else if isAIPending {
                aiLoadingState
            } else {
                notFoundState
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card))
        .cardShadow()
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(lookup.original)
                    .font(AppFonts.display(30, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                if lookup.lemma.lowercased() != lookup.original.lowercased() {
                    Text("→ \(lookup.lemma)")
                        .font(AppFonts.mono(11))
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: AppSpacing.sm) {
                Button(action: {
                    addedToVocab.toggle()
                    onAddToVocab()
                }) {
                    Image(systemName: addedToVocab ? "star.fill" : "star")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(addedToVocab ? AppColors.brandPrimary : AppColors.textTertiary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppColors.bgPrimary))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Phonetic + Level

    private func phoneticAndLevel(entry: WordEntry) -> some View {
        HStack(spacing: AppSpacing.md) {
            if let phonetic = entry.phonetic {
                Button {
                    SpeechService.shared.speak(lookup.original)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.aiPrimary)
                        Text(phonetic)
                            .font(AppFonts.mono(13))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if let level = entry.level {
                Text(level)
                    .font(AppFonts.mono(10, weight: .bold))
                    .foregroundColor(AppColors.aiPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 2)
                    .background(AppColors.aiPrimary.opacity(0.18))
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Definitions

    private func definitions(entry: WordEntry) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(Array(entry.definitions.enumerated()), id: \.offset) { _, def in
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                    Text(def.pos)
                        .font(AppFonts.mono(10, weight: .bold))
                        .foregroundColor(AppColors.aiPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.aiPrimary.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text(def.meaning)
                        .font(AppFonts.body(15))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(.top, AppSpacing.xs)
    }

    // MARK: - Context Example

    private func contextExample(_ context: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("EXAMPLE")
                .font(AppFonts.body(10, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(AppColors.textTertiary)
            Text(context)
                .font(.system(size: 13).italic())
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppSpacing.xs)
    }

    // MARK: - CTAs

    private var ctaButtons: some View {
        HStack(spacing: AppSpacing.md) {
            Button { /* 完整释义占位 */ } label: {
                Text("完整释义")
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
            }
            .buttonStyle(.plain)

            Button(action: onAIDetail) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("AI 详解")
                }
                .font(AppFonts.body(13, weight: .medium))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.aiPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, AppSpacing.md)
    }

    // MARK: - AI Loading

    private var aiLoadingState: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(AppColors.aiPrimary)
                Text("AI 正在查询...")
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.aiPrimary)
            }
            Text("本地词典暂无收录，由 gpt-4o 实时生成")
                .font(AppFonts.body(11))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    // MARK: - Not Found

    private var notFoundState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(AppColors.textTertiary)
            Text("该词暂无释义")
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.textSecondary)
            Text("AI 查询失败，请检查网络")
                .font(AppFonts.body(11))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }
}

#Preview {
    let entry = WordEntry(
        phonetic: "/vɔɪs/", level: "A2",
        definitions: [
            WordDefinition(pos: "n.", meaning: "声音；嗓音"),
            WordDefinition(pos: "v.", meaning: "表达；说出")
        ]
    )
    let lookup = WordLookupResult(
        original: "voice",
        lemma: "voice",
        entry: entry,
        contextSentence: "The human voice is the most powerful sound in the world."
    )
    return ZStack {
        AppColors.bgPrimary.ignoresSafeArea()
        WordCard(lookup: lookup, isAIPending: false, onClose: {}, onAddToVocab: {}, onAIDetail: {})
    }
    .preferredColorScheme(.dark)
}
