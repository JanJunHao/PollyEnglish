import SwiftUI

/// 视频区透明手势层（文档 03.6）。
/// - 单击：切控件显隐
/// - 左 1/3 双击：-10s         /  上下滑：调亮度（HUD）
/// - 中央双击：播暂
/// - 右 1/3 双击：+10s         /  上下滑：调音量（HUD）
struct VideoGestureLayer: View {
    let onSingleTap: () -> Void
    let onDoubleTapLeft: () -> Void
    let onDoubleTapCenter: () -> Void
    let onDoubleTapRight: () -> Void
    let onBrightnessChange: (Double) -> Void  // 相对值 -1...1
    let onVolumeChange: (Double) -> Void

    var body: some View {
        HStack(spacing: 0) {
            zone(onDoubleTap: onDoubleTapLeft, onVerticalDrag: onBrightnessChange)
            zone(onDoubleTap: onDoubleTapCenter, onVerticalDrag: nil)
            zone(onDoubleTap: onDoubleTapRight, onVerticalDrag: onVolumeChange)
        }
    }

    private func zone(onDoubleTap: @escaping () -> Void,
                      onVerticalDrag: ((Double) -> Void)?) -> some View {
        ZoneView(onSingleTap: onSingleTap,
                 onDoubleTap: onDoubleTap,
                 onVerticalDrag: onVerticalDrag)
    }
}

private struct ZoneView: View {
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void
    let onVerticalDrag: ((Double) -> Void)?

    @State private var dragLastY: CGFloat?

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture(count: 2) { onDoubleTap() }
            .onTapGesture(count: 1) { onSingleTap() }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        guard let cb = onVerticalDrag else { return }
                        let prev = dragLastY ?? value.startLocation.y
                        let deltaY = prev - value.location.y  // 向上 = 正
                        // 200pt 拖到顶 = 1.0 全范围
                        let delta = Double(deltaY) / 200.0
                        cb(delta)
                        dragLastY = value.location.y
                    }
                    .onEnded { _ in
                        dragLastY = nil
                    }
            )
    }
}
