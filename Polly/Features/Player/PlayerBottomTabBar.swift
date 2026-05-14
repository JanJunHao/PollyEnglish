import SwiftUI

/// 设计稿 State 01 底部 5-Tab。
/// 字幕 tab 默认激活态。其他 tab 按点击触发对应 action。
struct PlayerBottomTabBar: View {
    @Binding var activeTab: Tab
    let onTap: (Tab) -> Void

    enum Tab: String, CaseIterable, Hashable {
        case speed     = "1.0×"
        case loop      = "循环"
        case ab        = "AB"
        case subtitle  = "字幕"
        case shadowing = "跟读"

        var systemImage: String {
            switch self {
            case .speed:     return "clock"
            case .loop:      return "arrow.clockwise"
            case .ab:        return "rectangle.split.2x1"
            case .subtitle:  return "text.justify"
            case .shadowing: return "mic"
            }
        }
    }

    /// 显示用文字（如倍速 tab 显示当前倍速）
    var speedLabel: String = "1.0×"
    var loopActive: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    onTap(tab)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .medium))
                        Text(displayLabel(for: tab))
                            .font(AppFonts.body(10))
                    }
                    .foregroundColor(highlightColor(for: tab))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 56)
    }

    private func displayLabel(for tab: Tab) -> String {
        if tab == .speed { return speedLabel }
        return tab.rawValue
    }

    private func highlightColor(for tab: Tab) -> Color {
        // 字幕：始终激活
        if tab == .subtitle { return AppColors.brandPrimary }
        // 循环：开启时高亮
        if tab == .loop, loopActive { return AppColors.brandPrimary }
        return AppColors.textTertiary
    }
}
