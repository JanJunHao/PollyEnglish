import SwiftUI

/// 长文本进入视图后自动滚动一遍展示完整内容，结束后回到 `…` 省略状态。
///
/// 关键：用 ZStack 让两个 Text 视图（截断版 + 滚动版）始终共存，靠 opacity 切换，
/// 这样 `.offset` 动画作用于同一个 View 不会因 View tree 变化导致动画失效。
struct MarqueeText: View {
    let text: String
    let font: Font
    var foreground: Color = .primary

    @State private var contentWidth: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var didMarquee = false
    @State private var isScrolling = false

    var body: some View {
        GeometryReader { geo in
            let overflow = max(0, contentWidth - geo.size.width)

            ZStack(alignment: .leading) {
                // 静态截断版（默认可见，滚动时透明）。显式 maxWidth 约束让 truncationMode(.tail) 生效；
                // 否则 ZStack 整体被滚动版的 fixedSize 撑到全宽，静态版没有窄于内容的约束就不会出 `…`。
                Text(text)
                    .font(font)
                    .foregroundColor(foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: geo.size.width, alignment: .leading)
                    .opacity(isScrolling ? 0 : 1)

                // 滚动版（默认透明，动画期间可见）
                Text(text)
                    .font(font)
                    .foregroundColor(foreground)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: offsetX)
                    .opacity(isScrolling ? 1 : 0)
            }
            .frame(width: geo.size.width, alignment: .leading)
            .clipped()
            // 用一份 .hidden() 副本测真实文本宽度
            .background(
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .hidden()
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: ContentWidthKey.self, value: proxy.size.width)
                        }
                    )
            )
            .onPreferenceChange(ContentWidthKey.self) { w in
                contentWidth = w
            }
            .onChange(of: contentWidth) { _, _ in
                tryStartMarquee(overflow: overflow)
            }
            .onAppear {
                // contentWidth 可能在 onAppear 时已经测出（同一帧 preference 已触发），主动判一次
                tryStartMarquee(overflow: overflow)
            }
        }
        .frame(height: 20)
    }

    private func tryStartMarquee(overflow: CGFloat) {
        guard !didMarquee, overflow > 0 else { return }
        didMarquee = true
        Task { @MainActor in
            // 半秒让用户先看到截断态
            try? await Task.sleep(nanoseconds: 600_000_000)
            isScrolling = true
            // 滚动速度 ≈ 30 pt/s，至少 2s
            let duration = max(2.0, Double(overflow) / 30.0)
            withAnimation(.linear(duration: duration)) {
                offsetX = -overflow
            }
            // 滚到末尾停 600ms 让人看清结尾
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.6) * 1_000_000_000))
            // 复位（不要肉眼可见的回卷动画，直接切回截断态）
            offsetX = 0
            isScrolling = false
        }
    }
}

private struct ContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
