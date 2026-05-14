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
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .subtitleTextShadow()
        }
    }

    private func wordHighlightedText(for seg: SubtitleSegment) -> Text {
        var result = Text("")
        for (i, word) in seg.words.enumerated() {
            let space = i == 0 ? "" : " "
            let color: Color
            if currentTime > word.e {
                color = .white.opacity(0.45)
            } else if currentTime >= word.s {
                color = AppColors.brandPrimary
            } else {
                color = .white
            }
            result = result + Text(space + word.w)
                .font(AppFonts.body(prefs.sizeFloatingEnglish, weight: .medium))
                .foregroundColor(color)
        }
        return result
    }
}
