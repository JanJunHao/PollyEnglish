import SwiftUI

/// 首页各 Section 的标题行（设计交付 v2 §2.2）：
/// 左侧 20pt SemiBold 标题，右侧可选 `查看更多 ›` 12.5pt 动作。
struct SectionHeader: View {
    @Environment(\.theme) private var theme
    let title: String
    var actionLabel: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppFonts.body(20, weight: .semibold))
                .foregroundColor(theme.text)

            Spacer(minLength: AppSpacing.sm)

            if let actionLabel, let onAction {
                Button(action: onAction) {
                    HStack(spacing: 2) {
                        Text(actionLabel)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .font(AppFonts.body(12.5))
                    .foregroundColor(theme.textSec)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }
}
