import SwiftUI

/// 视频区底部叠加的浮动字幕：当前句 + 字级三态高亮 + 中文翻译。
/// 设计稿 State 01 的视频区底部就是这个组件。
/// 文字阴影确保在任何视频背景下都清晰可读（文档 03.5）。
struct FloatingSubtitleView: View {
    let segment: SubtitleSegment?
    let currentTime: Double
    @ObservedObject var prefs: SubtitlePreferences

    var body: some View {
        if let seg = segment {
            VStack(spacing: 2) {
                if prefs.showEnglish {
                    wordHighlightedText(for: seg)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }

                if prefs.showChinese, let translation = seg.translation, !translation.isEmpty {
                    Text(translation)
                        .font(AppFonts.body(prefs.sizeFloatingChinese))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
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
