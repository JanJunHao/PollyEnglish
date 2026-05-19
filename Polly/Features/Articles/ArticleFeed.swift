import SwiftUI

/// 外刊 tab 内容（设计交付 v2 §2.3）：编辑精选 Hero + 最新外刊列表 + 合作刊源。
struct ArticleFeed: View {
    @Environment(\.theme) private var theme
    @StateObject private var service = ArticleService.shared
    @State private var presentedArticle: Article?

    var body: some View {
        Group {
            if let hero = service.articles.first {
                feed(hero: hero, rest: Array(service.articles.dropFirst()))
            } else if let error = service.lastError {
                stateView(icon: "wifi.exclamationmark", title: "无法加载外刊", detail: error)
            } else {
                loadingView
            }
        }
        .task {
            if service.articles.isEmpty { await service.refresh() }
        }
        .fullScreenCover(item: $presentedArticle) { article in
            ArticleDetailView(article: article) { presentedArticle = nil }
        }
    }

    private func feed(hero: Article, rest: [Article]) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("EDITOR'S PICK · \(hero.relativeDate.uppercased())")
                    .font(AppFonts.mono(10, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(theme.aiText)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                Button { presentedArticle = hero } label: {
                    ArticleHero(article: hero)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)

                SectionHeader(title: "最新外刊")

                if rest.isEmpty {
                    Text("暂无更多外刊")
                        .font(AppFonts.body(12))
                        .foregroundColor(theme.textTer)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(rest.enumerated()), id: \.element.id) { idx, article in
                            Button { presentedArticle = article } label: {
                                ArticleRow(article: article, isLast: idx == rest.count - 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                }

                PartnerSourcesCard(sources: distinctSources)
                    .padding(.horizontal, 22)
                    .padding(.top, 22)

                Spacer(minLength: 100)
            }
        }
        .refreshable { await service.refresh() }
    }

    /// 文章里出现过的去重刊源（保序）。
    private var distinctSources: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for article in service.articles where seen.insert(article.source).inserted {
            ordered.append(article.source)
        }
        return ordered
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView().tint(theme.textTer)
            Text("加载外刊中…")
                .font(AppFonts.body(13))
                .foregroundColor(theme.textTer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stateView(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .regular))
                .foregroundColor(theme.textTer)
            Text(title)
                .font(AppFonts.body(15, weight: .semibold))
                .foregroundColor(theme.text)
            Button {
                Task { await service.refresh() }
            } label: {
                Text("重试")
                    .font(AppFonts.body(13, weight: .semibold))
                    .foregroundColor(theme.text)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.sm)
                    .background(theme.surfaceElev, in: RoundedRectangle(cornerRadius: AppRadii.chip))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 合作刊源 stat 卡。
private struct PartnerSourcesCard: View {
    @Environment(\.theme) private var theme
    let sources: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("合作刊源 · \(sources.count)")
                .font(AppFonts.body(11, weight: .semibold))
                .foregroundColor(theme.textSec)

            FlowChips(items: sources)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surfaceSubtle)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.divider, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 刊源名 chip 自动换行排布。
private struct FlowChips: View {
    @Environment(\.theme) private var theme
    let items: [String]

    var body: some View {
        FlowLayout(hSpacing: 6, vSpacing: 6) {
            ForEach(items, id: \.self) { name in
                Text(name)
                    .font(AppFonts.display(11.5, weight: .regular).italic())
                    .foregroundColor(theme.textSec)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
