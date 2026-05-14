import SwiftUI

struct LearningPlaceholder: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("我的学习")
                .font(AppFonts.body(17, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.lg)

            Button(action: action) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.brandPrimary)

                    Text("查看生词本与收藏")
                        .font(AppFonts.body(14))
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(AppColors.bgElevated)
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
