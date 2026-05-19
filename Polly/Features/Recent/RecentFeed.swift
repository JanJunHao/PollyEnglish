import SwiftUI

/// 最近更新 feed 的一条：视频或文章，带统一的更新时间戳。
enum RecentItem: Identifiable {
    case video(DemoVideo)
    case article(Article)

    var id: String {
        switch self {
        case .video(let v):   return "v-\(v.id)"
        case .article(let a): return "a-\(a.id)"
        }
    }

    var date: Date {
        switch self {
        case .video(let v):   return v.updatedAt
        case .article(let a): return a.updatedAt
        }
    }
}

/// 最近更新 tab（设计交付 v2 §2.4）：视频 + 外刊按时间倒序、分日期分组的混合 feed。
struct RecentFeed: View {
    @Environment(\.theme) private var theme
    @StateObject private var contentService = ContentService.shared
    @StateObject private var articleService = ArticleService.shared
    @State private var allRead = false

    /// 视频打开回调（文章暂无阅读页，不可点）。
    var onOpenVideo: (DemoVideo) -> Void

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        let items = mergedItems
        Group {
            if items.isEmpty {
                loadingView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerStrip(weekly: weeklyCount(items))

                        ForEach(groupedItems(items), id: \.label) { group in
                            dateDivider(label: group.label, count: group.items.count)
                            VStack(spacing: 0) {
                                ForEach(group.items) { item in
                                    row(for: item, isToday: group.label == "今天")
                                }
                            }
                            .padding(.horizontal, 14)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .task {
            if articleService.articles.isEmpty { await articleService.refresh() }
        }
    }

    // MARK: - 数据组装

    /// 视频 + 文章合并，按更新时间倒序。
    private var mergedItems: [RecentItem] {
        let vids = contentService.videos.map(RecentItem.video)
        let arts = articleService.articles.map(RecentItem.article)
        return (vids + arts).sorted { $0.date > $1.date }
    }

    private struct DateGroup { let label: String; let items: [RecentItem] }

    /// 按自然日分组（输入已按时间倒序，分组顺序即最新在前）。
    private func groupedItems(_ items: [RecentItem]) -> [DateGroup] {
        let cal = Calendar.current
        var order: [String] = []
        var buckets: [String: [RecentItem]] = [:]
        for item in items {
            let label = dayLabel(item.date, cal: cal)
            if buckets[label] == nil { order.append(label) }
            buckets[label, default: []].append(item)
        }
        return order.map { DateGroup(label: $0, items: buckets[$0] ?? []) }
    }

    private func dayLabel(_ date: Date, cal: Calendar) -> String {
        let days = cal.dateComponents(
            [.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())
        ).day ?? 0
        switch days {
        case ..<1: return "今天"
        case 1:    return "昨天"
        default:   return "\(days) 天前"
        }
    }

    /// 近 7 天内新增条数。
    private func weeklyCount(_ items: [RecentItem]) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        return items.filter { $0.date >= weekAgo }.count
    }

    private func addedAtLabel(_ date: Date) -> String {
        "\(dayLabel(date, cal: .current)) \(Self.timeFormatter.string(from: date))"
    }

    // MARK: - 顶部状态条

    private func headerStrip(weekly: Int) -> some View {
        HStack(spacing: 10) {
            PulseDot(color: theme.brand)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("本周新增 ")
                    Text("\(weekly)").foregroundColor(theme.brandText)
                    Text(" 条")
                }
                .font(AppFonts.body(13, weight: .semibold))
                .foregroundColor(theme.text)

                Text("视频与外刊持续更新，AI 已完成加工")
                    .font(AppFonts.body(11))
                    .foregroundColor(theme.textSec)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { allRead = true }
            } label: {
                Text(allRead ? "已读" : "全部已读")
                    .font(AppFonts.body(11.5, weight: .medium))
                    .foregroundColor(allRead ? theme.textTer : theme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.chipBgActive, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(allRead)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [theme.brand.opacity(0.08), theme.ai.opacity(0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.brand.opacity(0.2), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // MARK: - 日期分隔

    private func dateDivider(label: String, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(AppFonts.body(13, weight: .semibold))
                .foregroundColor(theme.text)
            Rectangle()
                .fill(theme.chipBgActive)
                .frame(height: 0.5)
            Text("\(count) ITEM\(count == 1 ? "" : "S")")
                .font(AppFonts.mono(9.5))
                .tracking(0.5)
                .foregroundColor(theme.textTer)
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - 条目行

    @ViewBuilder
    private func row(for item: RecentItem, isToday: Bool) -> some View {
        switch item {
        case .video(let video):
            RecentRow(
                kind: .video,
                cover: AnyView(videoCover(video)),
                isNew: isToday && !allRead,
                eyebrow: "\(video.source) · \(video.author.split(separator: " ").first.map { $0.uppercased() } ?? "")",
                title: video.title,
                titleFont: AppFonts.body(13.5, weight: .medium),
                metaLevel: video.cefrLevel,
                metaTail: addedAtLabel(video.updatedAt),
                onTap: { onOpenVideo(video) }
            )
        case .article(let article):
            RecentRow(
                kind: .article,
                cover: AnyView(articleCover(article)),
                isNew: isToday && !allRead,
                eyebrow: article.source.uppercased(),
                title: article.title,
                titleFont: AppFonts.display(14.5, weight: .medium),
                metaLevel: article.cefrLevel,
                metaTail: "\(article.readingMinutes) min · \(addedAtLabel(article.updatedAt))",
                onTap: nil
            )
        }
    }

    private func videoCover(_ video: DemoVideo) -> some View {
        ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
            .aspectRatio(contentMode: .fill)
            .frame(width: 96, height: 64)
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                Text(video.durationDisplay)
                    .font(AppFonts.mono(8.5, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
    }

    private func articleCover(_ article: Article) -> some View {
        ZStack {
            article.style.gradient
            Text(article.style.abbreviation)
                .font(AppFonts.display(20, weight: .medium).italic())
                .foregroundColor(article.style.inkColor)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
        }
        .frame(width: 96, height: 64)
        .overlay(alignment: .bottom) {
            Text(article.section)
                .font(AppFonts.mono(7.5, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 12)
                .background(.black.opacity(0.5))
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView().tint(theme.textTer)
            Text("加载最近更新中…")
                .font(AppFonts.body(13))
                .foregroundColor(theme.textTer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 通用行

/// 视频 / 文章共用的更新行：96×64 封面 + 类型徽章 + 标题 + meta。
private struct RecentRow: View {
    enum Kind { case video, article }

    @Environment(\.theme) private var theme
    let kind: Kind
    let cover: AnyView
    let isNew: Bool
    let eyebrow: String
    let title: String
    let titleFont: Font
    let metaLevel: String
    let metaTail: String
    let onTap: (() -> Void)?

    var body: some View {
        let content = HStack(alignment: .top, spacing: 12) {
            cover.clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    if isNew {
                        Circle().fill(Color(hex: 0xFF6E6E)).frame(width: 5, height: 5)
                    }
                    TypeBadge(kind: kind)
                    Text(eyebrow)
                        .font(AppFonts.mono(9.5))
                        .foregroundColor(theme.textTer)
                        .lineLimit(1)
                }

                Text(title)
                    .font(titleFont)
                    .foregroundColor(theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)

                HStack(spacing: 0) {
                    Text(metaLevel).foregroundColor(theme.aiText)
                    Text(" · ")
                    Text(metaTail)
                }
                .font(AppFonts.mono(9.5))
                .foregroundColor(theme.textTer)
                .padding(.top, 5)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.divider).frame(height: 0.5)
        }

        if let onTap {
            Button(action: onTap) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }
}

/// 视频 / 外刊 类型小徽章。
private struct TypeBadge: View {
    @Environment(\.theme) private var theme
    let kind: RecentRow.Kind

    var body: some View {
        let isVideo = kind == .video
        Text(isVideo ? "视频" : "外刊")
            .font(AppFonts.mono(9, weight: .bold))
            .tracking(0.5)
            .foregroundColor(isVideo ? theme.brandText : theme.aiText)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (isVideo ? theme.brand : theme.ai).opacity(0.22),
                in: RoundedRectangle(cornerRadius: 4)
            )
    }
}

/// 顶部状态条的脉冲黄点。
private struct PulseDot: View {
    let color: Color
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.9), radius: pulsing ? 5 : 1)
            .scaleEffect(pulsing ? 1 : 0.7)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)
            .onAppear { pulsing = true }
    }
}
