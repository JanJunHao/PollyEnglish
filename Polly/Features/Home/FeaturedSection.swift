import SwiftUI

/// 热门精选 Section（设计交付 v2 §2.2 C）：横滑课程卡，单卡 170×220。
struct FeaturedSection: View {
    let videos: [DemoVideo]
    let onSelect: (DemoVideo) -> Void
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(
                title: "热门精选",
                actionLabel: onSeeAll != nil ? "查看更多" : nil,
                onAction: onSeeAll
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(videos) { video in
                        FeaturedCard(video: video) { onSelect(video) }
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
}

/// 单张精选卡：96pt 缩略图 + source 标签 + 标题 + 时长等级。
private struct FeaturedCard: View {
    @Environment(\.theme) private var theme
    let video: DemoVideo
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 170, height: 96)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.source.uppercased())
                        .font(AppFonts.display(11.5, weight: .regular).italic())
                        .foregroundColor(theme.brandText)
                        .tracking(1.5)
                        .lineLimit(1)

                    Text(video.title)
                        .font(AppFonts.body(13, weight: .medium))
                        .foregroundColor(theme.text)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 0)

                    Text("\(video.durationDisplay) · \(video.cefrLevel)")
                        .font(AppFonts.mono(9.5))
                        .foregroundColor(theme.textTer)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
            }
            .frame(width: 170, height: 220)
            .background(theme.surfaceElev)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
