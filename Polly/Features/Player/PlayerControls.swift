import SwiftUI

// MARK: - 控件按钮（默认支持长按持续，文档 03.9）
struct ControlIconButton: View {
    let systemName: String
    var size: CGFloat = 36
    /// 是否启用长按持续重复触发（上下句/±10s 需要；其他按钮可设 false）
    var repeating: Bool = true
    let action: () -> Void

    @State private var isPressed = false
    @State private var pressTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.08), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            action()  // 按下立即触发一次
                            if repeating {
                                pressTask = Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000)  // 等 0.5s
                                    guard !Task.isCancelled else { return }
                                    while !Task.isCancelled {
                                        await MainActor.run { action() }
                                        try? await Task.sleep(nanoseconds: 150_000_000)  // 每 0.15s 重复
                                    }
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        pressTask?.cancel()
                        pressTask = nil
                    }
            )
    }
}

struct PlayPauseButton: View {
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary)
                    .frame(width: 52, height: 52)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                    .offset(x: isPlaying ? 0 : 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 进度条（含精细拖动模式，文档 03.10）
struct ProgressBar: View {
    let progress: Double
    let onSeek: (Double) -> Void
    @State private var isDragging = false
    /// 精细拖动模式：手柄按住向上滑 > 30pt 进入，1 屏宽 = 上下 10 秒
    @State private var isFineMode = false
    @State private var fineDragStartY: CGFloat = 0
    @State private var fineDragStartProgress: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.textTertiary.opacity(0.3))
                    .frame(height: 2)
                Capsule()
                    .fill(LinearGradient(
                        colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, w * progress), height: 2)
                Circle()
                    .fill(.white)
                    .frame(width: isDragging ? 16 : 11,
                           height: isDragging ? 16 : 11)
                    .offset(x: max(0, w * progress) - (isDragging ? 8 : 5.5))
                    .animation(.easeOut(duration: 0.12), value: isDragging)
                    .overlay(
                        // 精细模式视觉提示
                        Group {
                            if isFineMode {
                                Circle()
                                    .stroke(AppColors.brandPrimary, lineWidth: 2)
                                    .frame(width: 28, height: 28)
                                    .offset(x: max(0, w * progress) - 14)
                            }
                        }
                    )
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            fineDragStartY = value.location.y
                            fineDragStartProgress = progress
                        }
                        let verticalDrag = value.startLocation.y - value.location.y
                        // 向上拖 > 30pt 进入精细模式（文档 03.10）
                        if verticalDrag > 30 {
                            if !isFineMode { isFineMode = true }
                            // 精细：1 屏宽 = 上下 10 秒，但在 progress 0-1 空间里相当于 10/duration
                            // 这里没拿到 duration，先用水平位移 / 10 作精细系数
                            let horizontalDelta = value.translation.width / w / 10
                            let newProgress = max(0, min(1, fineDragStartProgress + horizontalDelta))
                            onSeek(newProgress)
                        } else {
                            if isFineMode { isFineMode = false }
                            let p = max(0, min(1, value.location.x / w))
                            onSeek(p)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        isFineMode = false
                    }
            )
        }
        .frame(height: 28)
    }
}

// MARK: - 时间格式化
func formatTime(_ t: Double) -> String {
    guard t.isFinite, t >= 0 else { return "0:00" }
    let total = Int(t)
    return String(format: "%d:%02d", total / 60, total % 60)
}
