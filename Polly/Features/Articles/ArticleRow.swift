import SwiftUI

/// 最新外刊列表的横向 row（设计交付 v2 §2.3 B）。
struct ArticleRow: View {
    @Environment(\.theme) private var theme
    let article: Article
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            miniCover

            VStack(alignment: .leading, spacing: 0) {
                Text(article.source.uppercased())
                    .font(AppFonts.mono(9.5, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(theme.textTer)
                    .lineLimit(1)

                Text(article.title)
                    .font(AppFonts.display(14.5, weight: .medium))
                    .foregroundColor(theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    Text(article.cefrLevel)
                        .foregroundColor(theme.aiText)
                    Text("·")
                    Text("\(article.readingMinutes) min")
                    Text("·")
                    Text(article.relativeDate)
                }
                .font(AppFonts.mono(9.5))
                .foregroundColor(theme.textTer)
                .padding(.top, 6)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(theme.divider).frame(height: 0.5)
            }
        }
    }

    /// 64×78 出版物缩略色块：渐变 + 缩写 + 底部分类条。
    private var miniCover: some View {
        ZStack {
            article.style.gradient
            Text(article.style.abbreviation)
                .font(AppFonts.display(18, weight: .medium).italic())
                .foregroundColor(article.style.inkColor)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
        }
        .frame(width: 64, height: 78)
        .overlay(alignment: .bottom) {
            Text(article.section)
                .font(AppFonts.mono(8, weight: .bold))
                .tracking(0.5)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 14)
                .background(.black.opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
