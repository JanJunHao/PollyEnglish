import SwiftUI

/// Discover（首页）顶部三档分类。切换时下方内容区整块替换（非滚动联动）。
enum DiscoverTab: String, CaseIterable, Identifiable {
    case recommend = "推荐"
    case foreign   = "外刊"
    case recent    = "最近更新"

    var id: String { rawValue }
}

/// 状态栏下方固定不滚动的分类 tab 条（设计交付 v2 §2.1）。
/// 激活：17pt Bold + 18×3 黄色短下划线；未激活：14pt Medium `textTer`。
struct CategoryTabs: View {
    @Environment(\.theme) private var theme
    @Binding var selection: DiscoverTab

    var body: some View {
        HStack(alignment: .bottom, spacing: 22) {
            ForEach(DiscoverTab.allCases) { tab in
                tabButton(tab)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.divider)
                .frame(height: 0.5)
        }
    }

    private func tabButton(_ tab: DiscoverTab) -> some View {
        let active = tab == selection
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selection = tab }
        } label: {
            Text(tab.rawValue)
                .font(AppFonts.body(active ? 17 : 14, weight: active ? .bold : .medium))
                .foregroundColor(active ? theme.text : theme.textTer)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(active ? theme.brand : .clear)
                        .frame(width: 18, height: 3)
                        .padding(.bottom, 4)
                }
                .animation(.easeInOut(duration: 0.2), value: active)
        }
        .buttonStyle(.plain)
    }
}
