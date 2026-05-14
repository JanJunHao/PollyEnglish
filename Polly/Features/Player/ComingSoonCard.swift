import SwiftUI

/// "即将上线"占位卡片：AB 循环、跟读评分等共用。
struct ComingSoonCard: View {
    let icon: String
    let title: String
    let desc: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.textTertiary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(AppColors.bgElevated))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)

                Spacer()

                ZStack {
                    Circle()
                        .fill(AppColors.aiPrimary.opacity(0.15))
                        .frame(width: 90, height: 90)
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(AppColors.aiPrimary)
                }

                VStack(spacing: AppSpacing.sm) {
                    Text(title)
                        .font(AppFonts.display(22, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(desc)
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }

                Spacer()
            }
        }
    }
}
