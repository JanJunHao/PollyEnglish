import SwiftUI

/// 视频区上下滑亮度/音量时显示的居中 HUD（文档 03.6）。
struct HUDIndicator: View {
    enum Kind { case brightness, volume }
    let kind: Kind
    /// 0..1
    let value: Double

    private var iconName: String {
        switch kind {
        case .brightness:
            return value < 0.05 ? "sun.min" :
                   value < 0.4  ? "sun.min.fill" :
                   value < 0.75 ? "sun.max" : "sun.max.fill"
        case .volume:
            return value < 0.01 ? "speaker.slash.fill" :
                   value < 0.34 ? "speaker.wave.1.fill" :
                   value < 0.67 ? "speaker.wave.2.fill" : "speaker.wave.3.fill"
        }
    }

    private var title: String {
        switch kind { case .brightness: "亮度"; case .volume: "音量" }
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(.white)
            Text(title)
                .font(AppFonts.body(11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            // 进度条
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 110, height: 3)
                Capsule()
                    .fill(.white)
                    .frame(width: 110 * max(0, min(1, value)), height: 3)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.35)))
        )
    }
}
