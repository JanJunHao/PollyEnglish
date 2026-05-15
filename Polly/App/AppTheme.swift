import SwiftUI

// MARK: - Colors（设计 token，文档 03.3）

enum AppColors {
    static let bgPrimary = Color(hex: 0x0A0A0C)
    static let bgElevated = Color(.sRGB, red: 20/255, green: 20/255, blue: 24/255, opacity: 0.96)

    static let brandPrimary = Color(hex: 0xFFE066)
    static let brandSecondary = Color(hex: 0xFFC93B)

    static let aiPrimary = Color(hex: 0xB8C4FF)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xE8E8EB)
    static let textTertiary = Color(hex: 0x888888)

    // 字幕字级三态（文档 03.5）
    static let subtitleRead = Color.white.opacity(0.45)
    static let subtitleUnread = Color.white
    static let subtitleActive = brandPrimary

    // 中文字幕
    static let subtitleChinese = Color(hex: 0xB0B0B5)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - Fonts（文档 03.3）
// 现阶段 fallback 到系统字体；后续把 Fraunces / Inter / JetBrains Mono 打包进 Resources/Fonts/ 后再切回 custom。

enum AppFonts {
    /// 单词主体、品牌字（Fraunces 衬线）
    static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// 正文（Inter / PingFang SC）
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// 时间码、技术标签、音标 IPA（JetBrains Mono）
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Radii
enum AppRadii {
    static let card: CGFloat = 20
    static let cardSmall: CGFloat = 16
    static let chip: CGFloat = 12
}

// MARK: - Spacing（4/8/12/16/24/32 体系）
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Shadow 工具
extension View {
    /// 字幕文字描边：Netflix / YouTube 风格——文字像被一圈深色"勾边"，在任意视频背景下都看得清，
    /// 且不像深色背景胶囊那样压住画面。
    /// 四个 1pt 偏移的 0-radius 阴影合起来形成像素级勾边；外层一圈柔光让在亮背景上也分离。
    func subtitleTextShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.95), radius: 0, x: 1,  y: 0)
            .shadow(color: .black.opacity(0.95), radius: 0, x: -1, y: 0)
            .shadow(color: .black.opacity(0.95), radius: 0, x: 0,  y: 1)
            .shadow(color: .black.opacity(0.95), radius: 0, x: 0,  y: -1)
            .shadow(color: .black.opacity(0.55), radius: 3, x: 0,  y: 1)
    }

    /// 当前句左侧黄色发光条阴影
    func currentSentenceGlow() -> some View {
        shadow(color: AppColors.brandPrimary.opacity(0.4), radius: 8, x: 0, y: 0)
    }

    /// 浮层卡片阴影
    func cardShadow() -> some View {
        shadow(color: .black.opacity(0.6), radius: 32, x: 0, y: 8)
    }
}
