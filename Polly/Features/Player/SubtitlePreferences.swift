import SwiftUI

/// 字幕显示偏好（字号 + 语言模式）。本周用 @AppStorage 持久化。
@MainActor
final class SubtitlePreferences: ObservableObject {
    enum Language: String, CaseIterable, Identifiable {
        case bilingual
        case englishOnly
        case chineseOnly

        var id: String { rawValue }
        var label: String {
            switch self {
            case .bilingual:    return "双语"
            case .englishOnly:  return "仅英文"
            case .chineseOnly:  return "仅中文"
            }
        }
    }

    @AppStorage("subtitle.fontScale") var fontScale: Double = 1.0    // 0.85 - 1.4
    @AppStorage("subtitle.languageRaw") private var languageRaw: String = Language.bilingual.rawValue

    var language: Language {
        get { Language(rawValue: languageRaw) ?? .bilingual }
        set { languageRaw = newValue.rawValue; objectWillChange.send() }
    }

    var showEnglish: Bool { language != .chineseOnly }
    var showChinese: Bool { language != .englishOnly }

    var sizeEnglish: CGFloat { 15 * fontScale }
    var sizeChinese: CGFloat { 13 * fontScale }
    var sizeFloatingEnglish: CGFloat { 18 * fontScale }
    var sizeFloatingChinese: CGFloat { 13 * fontScale }
}
