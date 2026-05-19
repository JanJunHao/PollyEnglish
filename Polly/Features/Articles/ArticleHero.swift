import SwiftUI

/// 编辑精选 Hero 卡（设计交付 v2 §2.3 A）：上半彩色渐变封面 + 下半白底文字区。
struct ArticleHero: View {
    @Environment(\.theme) private var theme
    let article: Article

    var body: some View {
        VStack(spacing: 0) {
            cover
            body0
        }
        .background(theme.surfaceElev)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.divider, lineWidth: 0.5)
        )
        .shadow(color: theme.shadowCard.color, radius: theme.shadowCard.radius,
                x: theme.shadowCard.x, y: theme.shadowCard.y)
    }

    private var cover: some View {
        ZStack(alignment: .leading) {
            article.style.gradient
            DotTexture().opacity(0.16)

            VStack(alignment: .leading) {
                Text(article.source)
                    .font(AppFonts.display(22, weight: .medium).italic())
                    .foregroundColor(article.style.inkColor)
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 2)

                Spacer()

                HStack {
                    Text(article.section)
                        .font(AppFonts.mono(9.5, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    Text(article.relativeDate.uppercased())
                        .font(AppFonts.mono(9.5))
                        .tracking(0.5)
                        .foregroundColor(.white.opacity(0.75))
                }
            }
            .padding(18)
        }
        .frame(height: 130)
        .clipped()
    }

    private var body0: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(article.title)
                .font(AppFonts.display(22, weight: .medium))
                .foregroundColor(theme.text)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(article.excerpt)
                .font(AppFonts.body(13.5).italic())
                .foregroundColor(theme.textSec)
                .lineSpacing(3)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.top, 10)

            HStack(spacing: 8) {
                Text(article.cefrLevel)
                    .font(AppFonts.mono(9.5, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(theme.aiText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.ai.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))

                Text(article.lengthLabel)
                    .font(AppFonts.mono(10.5))
                    .foregroundColor(theme.textTer)
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
    }
}

/// 封面上的点状纹理（设计交付里的 SVG dot pattern）。
struct DotTexture: View {
    var body: some View {
        Canvas { context, size in
            let pitch: CGFloat = 7
            let dot = Path(ellipseIn: CGRect(x: 0, y: 0, width: 1.2, height: 1.2))
            var y: CGFloat = 1
            while y < size.height {
                var x: CGFloat = 1
                while x < size.width {
                    context.fill(dot.offsetBy(dx: x, dy: y), with: .color(.white))
                    x += pitch
                }
                y += pitch
            }
        }
        .allowsHitTesting(false)
    }
}
