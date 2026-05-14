import SwiftUI

/// AI 讲解卡。文档 04.11 + 设计稿 State 02 对齐。
/// 三态：loading / loaded / error。
struct ExplanationCard: View {
    enum State {
        case loading
        case loaded(ExplanationResult)
        case error(String)
    }

    let sentence: String
    let state: State
    let onClose: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            sentenceCard
            Divider().overlay(AppColors.textTertiary.opacity(0.2))

            switch state {
            case .loading:  loadingState
            case .loaded(let r): loadedState(r)
            case .error(let m): errorState(m)
            }

            disclaimer
        }
        .padding(AppSpacing.lg)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card))
        .cardShadow()
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.aiPrimary)
                Text("AI 讲解")
                    .font(AppFonts.body(15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
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

    private var sentenceCard: some View {
        Text(sentence)
            .font(AppFonts.body(14))
            .foregroundColor(AppColors.textSecondary)
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }

    private var loadingState: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .tint(AppColors.aiPrimary)
            Text("Claude 正在精读这句...")
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    private func loadedState(_ r: ExplanationResult) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                section(title: "地道翻译", body: r.natural_translation)
                section(title: "核心讲解", body: r.core_explanation)

                if !r.key_vocab.isEmpty {
                    sectionHeader("关键词汇")
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(Array(r.key_vocab.enumerated()), id: \.offset) { _, vocab in
                            vocabRow(vocab)
                        }
                    }
                }

                if let note = r.cultural_note, !note.isEmpty {
                    section(title: "文化背景", body: note)
                }
                if let grammar = r.grammar_point, !grammar.isEmpty {
                    section(title: "语法点", body: grammar)
                }
                if let pron = r.pronunciation_tip, !pron.isEmpty {
                    section(title: "发音 Tip", body: pron)
                }
                if let similar = r.similar_expressions, !similar.isEmpty {
                    sectionHeader("类似表达")
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(similar.enumerated()), id: \.offset) { _, expr in
                            HStack(alignment: .top, spacing: 6) {
                                Circle().fill(AppColors.aiPrimary).frame(width: 5, height: 5)
                                    .padding(.top, 7)
                                Text(expr)
                                    .font(AppFonts.body(13))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(AppColors.textTertiary)
            Text("讲解生成失败")
                .font(AppFonts.body(14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            Text(message)
                .font(AppFonts.body(11))
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                Text("重试")
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.brandPrimary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    private var disclaimer: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 10))
            Text("本讲解由 AI 生成，可能存在错误。")
        }
        .font(AppFonts.body(11))
        .foregroundColor(AppColors.textTertiary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppSpacing.xs)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppFonts.body(11, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(AppColors.textTertiary)
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            sectionHeader(title)
            Text(body)
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
        }
    }

    private func vocabRow(_ vocab: ExplanationResult.VocabItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Circle().fill(AppColors.aiPrimary).frame(width: 5, height: 5)
                .padding(.top, 7)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(vocab.word)
                        .font(AppFonts.body(13, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    if let register = vocab.register, !register.isEmpty, register != "null" {
                        Text(register)
                            .font(AppFonts.mono(9))
                            .foregroundColor(AppColors.aiPrimary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(AppColors.aiPrimary.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                Text(vocab.meaning)
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}
