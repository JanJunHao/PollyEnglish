import SwiftUI

/// 最新上架 Section（设计交付 v2 §2.2 E）：横滑卡，结构同精选卡但带 NEW 徽章 + 上架时间。
struct NewArrivalSection: View {
    let videos: [DemoVideo]
    let onSelect: (DemoVideo) -> Void
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(
                title: "最新上架",
                actionLabel: onSeeAll != nil ? "查看更多" : nil,
                onAction: onSeeAll
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(videos.enumerated()), id: \.element.id) { idx, video in
                        NewArrivalCard(
                            video: video,
                            isNew: idx == 0,
                            addedAt: addedLabel(idx),
                            onSelect: { onSelect(video) }
                        )
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }

    /// 上架时间占位文案（服务端 updated_at 接入后可改成真实相对时间）。
    private func addedLabel(_ index: Int) -> String {
        switch index {
        case 0:  return "今天"
        case 1:  return "昨天"
        default: return "\(index) 天前"
        }
    }
}

/// 单张最新上架卡：96pt 缩略图（可带 NEW 徽章）+ 上架时间 + 标题 + 时长等级。
private struct NewArrivalCard: View {
    @Environment(\.theme) private var theme
    let video: DemoVideo
    let isNew: Bool
    let addedAt: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 170, height: 96)
                    .clipped()
                    .overlay(alignment: .topLeading) {
                        if isNew {
                            Text("NEW")
                                .font(AppFonts.mono(9, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color(hex: 0xFF6E6E))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(8)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.brand)
                            .frame(width: 5, height: 5)
                        Text("上架于 \(addedAt)")
                            .font(AppFonts.mono(9.5, weight: .bold))
                            .foregroundColor(theme.textTer)
                    }

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
            .frame(width: 170, height: 230)
            .background(theme.surfaceElev)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
