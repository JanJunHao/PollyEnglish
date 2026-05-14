import SwiftUI

/// 反馈表单。本周仅占位（提交按钮显示「已提交」toast），上线前接 polly-server /v1/feedback。
struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss

    enum Category: String, CaseIterable, Identifiable {
        case bug, content, feature, other
        var id: String { rawValue }
        var label: String {
            switch self {
            case .bug:     return "App Bug"
            case .content: return "字幕/讲解内容"
            case .feature: return "功能建议"
            case .other:   return "其他"
            }
        }
        var icon: String {
            switch self {
            case .bug:     return "ant.fill"
            case .content: return "text.alignleft"
            case .feature: return "lightbulb.fill"
            case .other:   return "ellipsis.bubble.fill"
            }
        }
    }

    @State private var category: Category = .bug
    @State private var body_: String = ""
    @State private var contact: String = ""
    @State private var submitting = false
    @State private var submitted = false

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        categoryPicker

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            sectionTitle("详细描述")
                            ZStack(alignment: .topLeading) {
                                if body_.isEmpty {
                                    Text("可附上视频名、句子序号、复现步骤……")
                                        .font(AppFonts.body(13))
                                        .foregroundColor(AppColors.textTertiary)
                                        .padding(.horizontal, AppSpacing.md)
                                        .padding(.vertical, AppSpacing.md)
                                }
                                TextEditor(text: $body_)
                                    .font(AppFonts.body(13))
                                    .foregroundColor(AppColors.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 160)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.sm)
                            }
                            .background(AppColors.bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            sectionTitle("联系方式（可选）")
                            TextField("邮箱 / 微信，方便我们回复", text: $contact)
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.bgElevated)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        if submitted {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.brandPrimary)
                                Text("已提交，感谢反馈！")
                                    .font(AppFonts.body(13, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.brandPrimary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
                        }
                    }
                }

                Button(action: submit) {
                    HStack {
                        if submitting { ProgressView().tint(.black) }
                        Text(submitted ? "再写一条" : "提交")
                            .font(AppFonts.body(15, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(canSubmit ? AppColors.brandPrimary : AppColors.brandPrimary.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit || submitting)
            }
            .padding(AppSpacing.lg)
        }
    }

    private var header: some View {
        HStack {
            Text("反馈")
                .font(AppFonts.display(22, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.bgElevated))
            }
            .buttonStyle(.plain)
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("分类")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                ForEach(Category.allCases) { c in
                    Button { category = c } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: c.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(c.label)
                                .font(AppFonts.body(13, weight: .medium))
                            Spacer()
                        }
                        .foregroundColor(category == c ? .black : AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.md)
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .background(category == c ? AppColors.brandPrimary : AppColors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s)
            .font(AppFonts.body(11, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(AppColors.textTertiary)
    }

    private var canSubmit: Bool {
        body_.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5
    }

    private func submit() {
        if submitted {
            body_ = ""; contact = ""; submitted = false
            return
        }
        submitting = true
        // 本周占位：模拟提交，1s 后回执。上线接 POST /v1/feedback。
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run {
                submitting = false
                submitted = true
            }
        }
    }
}

#Preview {
    FeedbackSheet().preferredColorScheme(.dark)
}
