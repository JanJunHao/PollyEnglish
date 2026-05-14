import SwiftUI

/// 视频区下方的工具栏 chips（设计稿 State 01）。
/// 本周仅 AI 讲解 + 自动滚动接业务，其余占位。
struct ChipsToolbar: View {
    let isAutoScrollEnabled: Bool
    let onAIExplain: () -> Void
    let onToggleAutoScroll: () -> Void
    let onFavorite: () -> Void
    let onVocabulary: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ChipButton(
                    icon: "sparkles",
                    label: "AI 讲解",
                    style: .ai,
                    onTap: onAIExplain
                )
                ChipButton(
                    icon: isAutoScrollEnabled ? "arrow.down.circle.fill" : "arrow.down.circle",
                    label: "自动滚动",
                    style: isAutoScrollEnabled ? .activeYellow : .neutral,
                    onTap: onToggleAutoScroll
                )
                ChipButton(
                    icon: "star",
                    label: "收藏",
                    style: .neutral,
                    onTap: onFavorite
                )
                ChipButton(
                    icon: "text.justify",
                    label: "词汇",
                    style: .neutral,
                    onTap: onVocabulary
                )
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .frame(height: 48)
    }
}

private struct ChipButton: View {
    enum Style { case ai, activeYellow, neutral }

    let icon: String
    let label: String
    let style: Style
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(AppFonts.body(13, weight: .medium))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 7)
            .background(backgroundColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        switch style {
        case .ai:           return AppColors.aiPrimary
        case .activeYellow: return AppColors.brandPrimary
        case .neutral:      return AppColors.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .ai:           return AppColors.aiPrimary.opacity(0.18)
        case .activeYellow: return AppColors.brandPrimary.opacity(0.15)
        case .neutral:      return Color.white.opacity(0.06)
        }
    }
}
