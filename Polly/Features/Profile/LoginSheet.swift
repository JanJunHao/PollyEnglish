import SwiftUI
import AuthenticationServices

struct LoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userStore = UserStore.shared

    @State private var errorMessage: String?
    @State private var showComingSoon = false
    @State private var comingSoonTitle = ""

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                header

                VStack(spacing: AppSpacing.md) {
                    // Apple 登录暂时下线（Personal Team 不支持 Sign In with Apple，
                    // 升级到付费 Apple Developer Program 后把下一行取消注释即可恢复）
                    // appleSignInButton

                    placeholderButton(title: "使用手机号登录", icon: "iphone") {
                        comingSoonTitle = "手机号登录"
                        showComingSoon = true
                    }

                    placeholderButton(title: "使用邮箱登录", icon: "envelope.fill") {
                        comingSoonTitle = "邮箱登录"
                        showComingSoon = true
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                guestButton

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppFonts.body(12))
                        .foregroundColor(.red.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }

                Spacer()

                legal
            }
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)
        }
        .preferredColorScheme(.dark)
        .alert("即将上线", isPresented: $showComingSoon) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("\(comingSoonTitle) 正在开发中，敬请期待。当前可使用游客模式继续。")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.black)
            }

            Text("登录 Polly")
                .font(AppFonts.display(24, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            Text("同步学习进度、生词本、收藏与设置")
                .font(AppFonts.body(13))
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
    }

    // MARK: - Apple Sign In

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            handleAppleResult(result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "无法获取登录凭证"
                return
            }
            let displayName: String = {
                if let name = credential.fullName, let given = name.givenName ?? name.familyName, !given.isEmpty {
                    return [name.givenName, name.familyName].compactMap { $0 }.joined(separator: " ")
                }
                if let email = credential.email, let prefix = email.split(separator: "@").first {
                    return String(prefix)
                }
                return "Polly 用户"
            }()

            let user = PollyUser(
                id: credential.user,
                name: displayName,
                method: .apple,
                signedInAt: Date(),
                email: credential.email
            )
            userStore.signIn(user)
            dismiss()
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = "Apple 登录失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Placeholders

    private func placeholderButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(AppFonts.body(15, weight: .medium))
                Spacer()
            }
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.lg)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(AppColors.bgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.chip)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Guest

    private var guestButton: some View {
        Button {
            let user = PollyUser(
                id: "guest-\(UUID().uuidString.prefix(8))",
                name: "游客",
                method: .guest,
                signedInAt: Date(),
                email: nil
            )
            userStore.signIn(user)
            dismiss()
        } label: {
            Text("以游客模式继续")
                .font(AppFonts.body(14, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
                .underline()
        }
        .buttonStyle(.plain)
    }

    private var legal: some View {
        Text("登录即代表你同意《服务条款》与《隐私政策》")
            .font(AppFonts.body(11))
            .foregroundColor(AppColors.textTertiary.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.xl)
    }
}

#Preview {
    LoginSheet()
}
