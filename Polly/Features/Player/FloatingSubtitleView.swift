import SwiftUI

/// 视频区底部叠加的浮动字幕：当前句，纯英文。
/// 浮动字幕只是叠在画面上的伴读提示，固定纯英文；中英对照在下方字幕列表里有。
/// 文字阴影确保在任何视频背景下都清晰可读（文档 03.5）。
struct FloatingSubtitleView: View {
    let segment: SubtitleSegment?
    let currentTime: Double
    @ObservedObject var prefs: SubtitlePreferences

    var body: some View {
        if let seg = segment {
            wordHighlightedText(for: seg)
                .multilineTextAlignment(.center)
                // 长句允许换到 3 行；再长则等比缩字（最多缩到 80%），避免 "..." 截断
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                // 紧贴文字的轻量胶囊：横向只比文字宽 12pt，纵向比文字高 6pt；
                // 25% 黑保证白底视频也有对比，又不像满宽暗带那样压住画面。
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.03))
                )
                .subtitleTextShadow()
                .padding(.horizontal, AppSpacing.lg)
        }
    }

    private func wordHighlightedText(for seg: SubtitleSegment) -> Text {
        // 整句一直白色：浮动字幕只是个伴读提示，字级高亮在下方字幕列表已有，这里不再随时间变色。
        Text(seg.text)
            .font(AppFonts.body(prefs.sizeFloatingEnglish, weight: .medium))
            .foregroundColor(.white)
    }
}
