import SwiftUI

/// 内容分类标签。未来内容打标后自动归类到对应模块。
enum VideoCategory: String, CaseIterable, Identifiable, Codable {
    case dailyNews        = "daily_news"
    case movie            = "movie"
    case discovery        = "discovery"
    case ted              = "ted"
    case youtube          = "youtube"           // YouTube 嵌入类（TED 等）；需翻墙访问 googlevideo CDN
    case streetInterview  = "street_interview"
    case highlights       = "highlights"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dailyNews:       return "每日快讯"
        case .movie:           return "电影"
        case .discovery:       return "探索发现"
        case .ted:             return "TED"
        case .youtube:         return "YouTube"
        case .streetInterview: return "街头采访"
        case .highlights:      return "精彩片段"
        }
    }

    var icon: String {
        switch self {
        case .dailyNews:       return "newspaper.fill"
        case .movie:           return "film.fill"
        case .discovery:       return "globe.americas.fill"
        case .ted:             return "mic.fill"
        case .youtube:         return "play.rectangle.fill"
        case .streetInterview: return "person.2.fill"
        case .highlights:      return "star.bubble.fill"
        }
    }

    /// 模块标签的强调色（chip 底色 + 描边）
    var accentColorHex: UInt32 {
        switch self {
        case .dailyNews:       return 0xFF6B6B  // 红
        case .movie:           return 0x6B9DFF  // 蓝
        case .discovery:       return 0x4ECDC4  // 青
        case .ted:             return 0xFFE066  // 品牌黄
        case .youtube:         return 0xFF0033  // YouTube 红
        case .streetInterview: return 0xB8C4FF  // AI 紫蓝
        case .highlights:      return 0xFF9EC4  // 粉
        }
    }

    var accentColor: Color { Color(hex: accentColorHex) }

    /// 该分类是否依赖外网（YouTube 视频流需访问 googlevideo.com，国内被墙）。
    var requiresExternalNetwork: Bool { self == .youtube }
}
