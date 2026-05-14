import SwiftUI

/// 全局 paywall 触发器：402 quota_exceeded 时 PollyAPIClient 推过来；
/// RootTabView 监听弹 sheet。
///
/// StoreKit 2 实际购买流程未接入——按钮当前是 "Coming soon" 占位。
/// 接入步骤（plan「订阅与付费」）：
/// 1. App Store Connect 配 product id: com.pollyEnglish.app.plus.monthly / .pro.monthly
/// 2. 引 `Product.products(for:)` 加载、`product.purchase()` 购买
/// 3. 监听 `Transaction.updates`，通过 verificationResult 拿 originalID + expiresDate
/// 4. POST 到 polly-server 的 /v1/subscriptions（待建）做 Apple receipt 验签
@MainActor
final class PaywallManager: ObservableObject {
    static let shared = PaywallManager()

    @Published var isPresented: Bool = false
    @Published private(set) var triggerContext: TriggerContext?

    struct TriggerContext {
        let kind: String          // ai_explain / ai_word / ai_chat / pronunciation
        let currentTier: String   // free / plus / pro
        let upgradeTo: String     // plus / pro
    }

    private init() {}

    func trigger(kind: String, tier: String, upgradeTo: String) {
        self.triggerContext = TriggerContext(kind: kind, currentTier: tier, upgradeTo: upgradeTo)
        self.isPresented = true
    }
}

/// 3 档对比 + Coming soon 按钮的占位 paywall。
struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager: PaywallManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header
                tierCards
                footer
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.bgPrimary.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("解锁更多 Polly")
                        .font(AppFonts.display(28, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    if let ctx = manager.triggerContext {
                        Text("你已用完今日 \(humanKind(ctx.kind)) 配额")
                            .font(AppFonts.body(14))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppColors.bgElevated))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tierCards: some View {
        VStack(spacing: AppSpacing.md) {
            tierCard(
                tier: "free", title: "免费", price: "¥0",
                features: ["每天 20 句 AI 讲解", "30 次查词", "5 次对话练习", "10 次跟读评分"],
                cta: "当前档位", enabled: false,
                highlighted: manager.triggerContext?.currentTier == "free"
            )
            tierCard(
                tier: "plus", title: "Plus", price: "¥18/月",
                features: ["每天 200 句 AI 讲解", "500 次查词", "50 次对话练习", "100 次跟读评分", "更快响应"],
                cta: "升级 Plus · Coming Soon", enabled: false,
                highlighted: manager.triggerContext?.upgradeTo == "plus"
            )
            tierCard(
                tier: "pro", title: "Pro", price: "¥48/月",
                features: ["AI 讲解 / 查词 无上限", "200 次对话练习", "500 次跟读评分", "Claude Opus 模型"],
                cta: "升级 Pro · Coming Soon", enabled: false,
                highlighted: manager.triggerContext?.upgradeTo == "pro"
            )
        }
    }

    @ViewBuilder
    private func tierCard(tier: String, title: String, price: String,
                          features: [String], cta: String, enabled: Bool,
                          highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(AppFonts.body(20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(price)
                    .font(AppFonts.mono(15, weight: .semibold))
                    .foregroundColor(highlighted ? AppColors.brandPrimary : AppColors.textSecondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(features, id: \.self) { line in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(highlighted ? AppColors.brandPrimary : AppColors.textTertiary)
                            .padding(.top, 5)
                        Text(line)
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            Button {
                // StoreKit 2 hook 占位
            } label: {
                Text(cta)
                    .font(AppFonts.body(14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadii.cardSmall)
                            .fill(highlighted ? AppColors.brandPrimary : AppColors.bgElevated)
                    )
                    .foregroundColor(highlighted ? .black : AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadii.card)
                .fill(AppColors.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadii.card)
                        .strokeBorder(highlighted ? AppColors.brandPrimary : .clear, lineWidth: 1.5)
                )
        )
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("订阅功能开发中。当前显示为价格预览，按下不会真发生扣款。")
                .font(AppFonts.body(11))
                .foregroundColor(AppColors.textTertiary)
            Text("plan 05.7「付费转化五阶段漏斗」节奏：Day 0-1 哇时刻 → Day 14+ 转化。")
                .font(AppFonts.body(11))
                .foregroundColor(AppColors.textTertiary)
        }
    }

    private func humanKind(_ raw: String) -> String {
        switch raw {
        case "ai_explain": return "AI 讲解"
        case "ai_word":    return "AI 查词"
        case "ai_chat":    return "对话练习"
        case "pronunciation": return "跟读评分"
        default: return raw
        }
    }
}
