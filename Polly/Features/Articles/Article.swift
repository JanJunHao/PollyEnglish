import SwiftUI

/// 图文切段后的一句——精读交互（点词 / 整句讲解）以此为单位。对齐服务端 ArticleSegment。
struct ArticleSegment: Identifiable, Hashable {
    let id: Int
    let text: String
    let translation: String
    let paragraph: Int        // 句子所属自然段序号
}

/// 外刊文章。运行时由 ArticleService 从 /v1/articles/latest 拉取。
struct Article: Identifiable, Hashable {
    let id: String
    let title: String
    let source: String        // 出版物名
    let author: String
    let cefrLevel: String
    let topics: [String]
    let wordCount: Int
    let readingMinutes: Int
    let updatedAt: Date
    let excerpt: String
    let body: String          // 正文全文（段落以换行分隔）
    let paragraphs: [ArticleSegment]  // 逐句切段（每句带中文译文），精读页用
    let imageURLs: [String]   // 自托管配图
    let thumbnailURL: String  // 封面图
    let attribution: String?  // CC 许可署名

    /// 正文按自然段分组，给精读页逐段渲染。
    var paragraphsByParagraph: [[ArticleSegment]] {
        guard !paragraphs.isEmpty else { return [] }
        var groups: [[ArticleSegment]] = []
        var current: [ArticleSegment] = []
        var currentIndex = paragraphs[0].paragraph
        for seg in paragraphs {
            if seg.paragraph != currentIndex {
                groups.append(current)
                current = []
                currentIndex = seg.paragraph
            }
            current.append(seg)
        }
        if !current.isEmpty { groups.append(current) }
        return groups
    }

    /// 板块标签，取首个 topic 的大类（"science.nature" → "SCIENCE"）。
    var section: String {
        guard let first = topics.first, !first.isEmpty else { return "READING" }
        let head = first.split(separator: ".").first.map(String.init) ?? first
        return head.replacingOccurrences(of: "_", with: " ").uppercased()
    }

    var style: PublicationStyle { PublicationStyle.resolve(source: source) }

    /// 相对更新时间（今天 / 昨天 / N 天前）。
    var relativeDate: String {
        let days = Calendar.current.dateComponents([.day], from: updatedAt, to: Date()).day ?? 0
        switch days {
        case ..<1: return "今天"
        case 1:    return "昨天"
        default:   return "\(days) 天前"
        }
    }

    /// 字数 + 阅读时长，如 "1,240 words · 5 min read"。
    var lengthLabel: String {
        let words = wordCount.formatted(.number.grouping(.automatic))
        return "\(words) words · \(readingMinutes) min read"
    }
}

/// 出版物的视觉风格：封面渐变 + 封面上文字色 + 缩写。
/// 已知刊源用精选配色，未知刊源按名称稳定散列出色相。
struct PublicationStyle {
    let gradientTop: Color
    let gradientBottom: Color
    let inkColor: Color
    let abbreviation: String

    static func resolve(source: String) -> PublicationStyle {
        if let known = known[source] { return known }
        var hash = 5381
        for byte in source.utf8 { hash = ((hash << 5) &+ hash) &+ Int(byte) }
        let hue = Double(hash & 0xFFFF) / 65535.0
        return PublicationStyle(
            gradientTop: Color(hue: hue, saturation: 0.52, brightness: 0.52),
            gradientBottom: Color(hue: hue, saturation: 0.58, brightness: 0.20),
            inkColor: .white,
            abbreviation: autoAbbreviation(source)
        )
    }

    private static func autoAbbreviation(_ source: String) -> String {
        let words: [Substring] = source.split(separator: " ")
        var initials = ""
        for word in words.prefix(3) {
            if let first = word.first { initials.append(first) }
        }
        return initials.uppercased()
    }

    // 逐条 append 而非字典字面量：避免大字面量触发编译器类型检查超时。
    static let known: [String: PublicationStyle] = {
        var map: [String: PublicationStyle] = [:]
        map["Simple English Wikipedia"] = PublicationStyle(
            gradientTop: Color(hex: 0x3A6EA5), gradientBottom: Color(hex: 0x16243A),
            inkColor: Color.white, abbreviation: "WIKI")
        map["Wikinews"] = PublicationStyle(
            gradientTop: Color(hex: 0x4F7A3A), gradientBottom: Color(hex: 0x1B2814),
            inkColor: Color.white, abbreviation: "WN")
        map["Project Gutenberg"] = PublicationStyle(
            gradientTop: Color(hex: 0x9A7B43), gradientBottom: Color(hex: 0x3A2C16),
            inkColor: Color.white, abbreviation: "PG")
        map["VOA Learning English"] = PublicationStyle(
            gradientTop: Color(hex: 0xC42E2E), gradientBottom: Color(hex: 0x4A0E0E),
            inkColor: Color.white, abbreviation: "VOA")
        return map
    }()

    var gradient: LinearGradient {
        LinearGradient(colors: [gradientTop, gradientBottom],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
