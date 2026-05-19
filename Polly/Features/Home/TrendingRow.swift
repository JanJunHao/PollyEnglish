import SwiftUI

/// 热门推荐的统计数据。服务端暂无 view_count / growth 信号，
/// 这里按 video.id 稳定散列出可信的占位数字（同一视频每次结果一致）。
struct TrendingStats {
    let viewsLabel: String   // 如 "12.4K 人在学"
    let growthLabel: String  // 如 "32%"

    static func derive(for video: DemoVideo) -> TrendingStats {
        var hash = 5381
        for byte in video.id.utf8 { hash = ((hash << 5) &+ hash) &+ Int(byte) }
        let mag = hash & 0x7FFFFFFF
        let viewsK = Double(20 + mag % 130) / 10.0   // 2.0 – 14.9 K
        let growth = 8 + (mag / 7) % 28              // 8 – 35 %
        return TrendingStats(
            viewsLabel: String(format: "%.1fK 人在学", viewsK),
            growthLabel: "\(growth)%"
        )
    }
}

/// 热门推荐 Section（设计交付 v2 §2.2 B）：3 行排行榜。
struct TrendingSection: View {
    let videos: [DemoVideo]
    let onSelect: (DemoVideo) -> Void
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(
                title: "热门推荐",
                actionLabel: onSeeAll != nil ? "查看更多" : nil,
                onAction: onSeeAll
            )
            VStack(spacing: 0) {
                ForEach(Array(videos.enumerated()), id: \.element.id) { idx, video in
                    TrendingRow(
                        video: video,
                        rank: idx + 1,
                        isLast: idx == videos.count - 1,
                        onSelect: { onSelect(video) }
                    )
                }
            }
            .padding(.horizontal, 14)
        }
    }
}

/// 排行榜单行：大编号 + 72×72 缩略图 + 标题 + 在学/增长 meta。
struct TrendingRow: View {
    @Environment(\.theme) private var theme
    let video: DemoVideo
    let rank: Int
    let isLast: Bool
    let onSelect: () -> Void

    var body: some View {
        let stats = TrendingStats.derive(for: video)
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Text(String(format: "%02d", rank))
                    .font(AppFonts.display(36, weight: .medium).italic())
                    .foregroundColor(rank == 1 ? theme.brandText : theme.textSec)
                    .lineLimit(1)
                    .fixedSize()                       // 两位数不换行
                    .frame(width: 48, alignment: .center)

                ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 5) {
                    Text(video.title)
                        .font(AppFonts.body(13.5, weight: .medium))
                        .foregroundColor(theme.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text(stats.viewsLabel)
                        Text("·")
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 8, weight: .bold))
                            Text(stats.growthLabel)
                        }
                        .foregroundColor(Color(hex: 0xFF9F6E))
                    }
                    .font(AppFonts.mono(10))
                    .foregroundColor(theme.textTer)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(theme.divider)
                    .frame(height: 0.5)
            }
        }
    }
}
