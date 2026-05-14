import SwiftUI

/// 启动过渡页：黑底 + 品牌黄 Polly 字 + 中文副标题 + 进度光圈。
/// LaunchScreen.storyboard 只配纯黑底，承接到这里 0.9s 内淡出进 RootTabView——
/// 这样副标题中文字体由 iOS 系统提供（PingFang SC），不会出现方框。
struct SplashView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @State private var showContent = false
    @State private var logoScale: CGFloat = 0.85
    @State private var logoOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var splashHidden = false
    @State private var ringPhase: Double = 0

    private let splashDuration: Double = 0.9

    var body: some View {
        ZStack {
            content()
                .opacity(showContent ? 1 : 0)

            if !splashHidden {
                splashOverlay
                    .transition(.opacity)
            }
        }
        .onAppear { runSequence() }
    }

    private var splashOverlay: some View {
        ZStack {
            // 纯黑底 + 极淡品牌色辐射，呼应 demo 的 "暖色光晕" 设计
            AppColors.bgPrimary
                .ignoresSafeArea()
                .overlay(
                    RadialGradient(
                        colors: [
                            AppColors.brandPrimary.opacity(0.10),
                            AppColors.brandPrimary.opacity(0.0),
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 320
                    )
                    .ignoresSafeArea()
                )

            VStack(spacing: 18) {
                // logo: 品牌黄 Polly + 黑色 ✦ 装饰
                ZStack {
                    rotatingRing
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Polly")
                            .font(.system(size: 56, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .tracking(-0.5)
                        Text("✦")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.brandPrimary)
                            .offset(y: -18)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // 副标题：英语精读 · 句句深耕
                HStack(spacing: 10) {
                    Text("英语精读")
                        .tracking(6)
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.6))
                        .frame(width: 3, height: 3)
                    Text("句句深耕")
                        .tracking(6)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textSecondary.opacity(0.7))
                .opacity(subtitleOpacity)
            }
        }
    }

    /// 旋转细环，给 logo 一点品牌动感
    private var rotatingRing: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [
                        AppColors.brandPrimary.opacity(0.0),
                        AppColors.brandPrimary.opacity(0.4),
                        AppColors.brandPrimary.opacity(0.0),
                    ],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
            )
            .frame(width: 200, height: 200)
            .rotationEffect(.degrees(ringPhase))
            .opacity(logoOpacity)
    }

    private func runSequence() {
        // 入场：logo 渐显 + 微微放大
        withAnimation(.easeOut(duration: 0.45)) {
            logoOpacity = 1
            logoScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
            subtitleOpacity = 1
        }
        // 旋转环：一直转直到 splash 退场
        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
            ringPhase = 360
        }

        // 在 splashDuration 后切到主内容
        DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration) {
            showContent = true
            withAnimation(.easeInOut(duration: 0.35)) {
                logoOpacity = 0
                subtitleOpacity = 0
                logoScale = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.25)) {
                    splashHidden = true
                }
            }
        }
    }
}

#Preview {
    SplashView {
        Text("Main").foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.bgPrimary)
    }
    .preferredColorScheme(.dark)
}
