import SwiftUI

/// 字幕设置面板（从顶栏 ⋯ 弹出）。
struct SubtitleSettingsSheet: View {
    @ObservedObject var prefs: SubtitlePreferences
    let onClose: () -> Void

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    sectionTitle("字幕语言")
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(SubtitlePreferences.Language.allCases) { lang in
                            let active = prefs.language == lang
                            Button {
                                prefs.language = lang
                            } label: {
                                Text(lang.label)
                                    .font(AppFonts.body(13, weight: .medium))
                                    .foregroundColor(active ? AppColors.brandPrimary : AppColors.textPrimary)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(active ? AppColors.brandPrimary.opacity(0.18) : Color.white.opacity(0.06))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    sectionTitle("字号 \(Int(prefs.fontScale * 100))%")
                    Slider(value: $prefs.fontScale, in: 0.85...1.4, step: 0.05)
                        .tint(AppColors.brandPrimary)
                    HStack {
                        Text("Aa").font(AppFonts.body(12)).foregroundColor(AppColors.textTertiary)
                        Spacer()
                        Text("Aa").font(AppFonts.body(20, weight: .semibold)).foregroundColor(AppColors.textTertiary)
                    }
                }

                Spacer()
            }
            .padding(AppSpacing.lg)
        }
    }

    private var header: some View {
        HStack {
            Text("字幕设置")
                .font(AppFonts.display(20, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
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
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(AppFonts.body(11, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(AppColors.textTertiary)
    }
}
