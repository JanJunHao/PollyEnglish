import SwiftUI

struct AboutSheet: View {
    let onClose: () -> Void

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(v) (\(b))"
    }

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

                Spacer()

                VStack(spacing: AppSpacing.md) {
                    if let img = UIImage(named: "AppIcon-1024") ?? UIImage(named: "AppIcon") {
                        Image(uiImage: img).resizable()
                            .frame(width: 84, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        Image(systemName: "bird.fill")
                            .font(.system(size: 56))
                            .foregroundColor(AppColors.brandPrimary)
                    }
                    Text("Polly")
                        .font(AppFonts.display(28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("视频精读 · 中文母语者的英语 App")
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.textTertiary)
                    Text("版本 \(version)")
                        .font(AppFonts.mono(11))
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                VStack(spacing: AppSpacing.sm) {
                    linkRow(title: "服务条款", icon: "doc.text")
                    linkRow(title: "隐私政策", icon: "lock.shield")
                }
            }
            .padding(AppSpacing.lg)
        }
    }

    private func linkRow(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 24)
            Text(title)
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 44)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }
}
