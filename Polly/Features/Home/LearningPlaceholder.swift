import SwiftUI

struct LearningPlaceholder: View {
    @Environment(\.theme) private var theme
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("我的学习")
                .font(AppFonts.body(17, weight: .semibold))
                .foregroundColor(theme.text)
                .padding(.horizontal, AppSpacing.lg)

            Button(action: action) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.brandText)

                    Text("查看生词本与收藏")
                        .font(AppFonts.body(14))
                        .foregroundColor(theme.textSec)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textTer)
                }
                .padding(.horizontal, AppSpacing.lg)
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(theme.surfaceElev)
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}

#Preview {
    LearningPlaceholder(action: {})
        .preferredColorScheme(.dark)
        .background(AppColors.bgPrimary)
}
