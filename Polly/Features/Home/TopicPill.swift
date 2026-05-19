import SwiftUI

/// 首页「主题探索」的主题数据（设计交付 v2 §2.2 F）。
struct HomeTopic: Identifiable {
    let id: String
    let name: String
    let count: Int
    let colorHex: UInt32
    let glyph: String

    var color: Color { Color(hex: colorHex) }

    static let all: [HomeTopic] = [
        HomeTopic(id: "comm", name: "表达与演讲", count: 24, colorHex: 0xFFE066, glyph: "🎤"),
        HomeTopic(id: "psy",  name: "心理与思维", count: 18, colorHex: 0xB8C4FF, glyph: "🧠"),
        HomeTopic(id: "sci",  name: "科技与未来", count: 31, colorHex: 0x7FD4FF, glyph: "⚛️"),
        HomeTopic(id: "biz",  name: "商业与职场", count: 22, colorHex: 0xFF9F6E, glyph: "📊"),
        HomeTopic(id: "life", name: "生活与日常", count: 16, colorHex: 0xA6E8C3, glyph: "☕️"),
        HomeTopic(id: "art",  name: "艺术与设计", count: 11, colorHex: 0xF0A0FF, glyph: "🎨"),
        HomeTopic(id: "news", name: "新闻与评论", count: 28, colorHex: 0xFFB8B8, glyph: "📰"),
    ]
}

/// 主题探索 Section：横滑主题 chip。
struct TopicSection: View {
    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "主题探索")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HomeTopic.all) { topic in
                        TopicPill(topic: topic)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
}

/// 单个主题 chip：左侧色块 + emoji，右侧主题名 + 视频数。
struct TopicPill: View {
    @Environment(\.theme) private var theme
    let topic: HomeTopic

    var body: some View {
        HStack(spacing: 8) {
            Text(topic.glyph)
                .font(.system(size: 16))
                .frame(width: 30, height: 30)
                .background(topic.color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text(topic.name)
                    .font(AppFonts.body(13, weight: .semibold))
                    .foregroundColor(theme.text)
                Text("\(topic.count) videos")
                    .font(AppFonts.mono(9.5))
                    .foregroundColor(theme.textTer)
            }
        }
        .padding(.init(top: 12, leading: 12, bottom: 12, trailing: 14))
        .background(topic.color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(topic.color.opacity(0.2), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
