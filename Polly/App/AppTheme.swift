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

// MARK: - 主题系统（设计交付 v2 ·「主题系统」一节）

/// 主题档位。`@AppStorage("theme")` 存这三档，`system` 跟随 iOS 全局深浅。
enum ThemeMode: String, CaseIterable {
    case system, dark, light
}

/// 卡片阴影 token（对应 CSS `box-shadow: x y radius color`）。
struct ThemeShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

/// 一套主题的全部设计 token。所有 view 应通过 `@Environment(\.theme)` 取色，不再硬编码。
protocol ThemeTokens {
    var bg: Color { get }            // 页面主背景
    var surface: Color { get }       // 卡片表面（含 list row）
    var surfaceSubtle: Color { get } // 浅微妙背景
    var surfaceElev: Color { get }   // 浮层（WordCard / AICard / sheet）

    var text: Color { get }          // 主要文字
    var textSec: Color { get }       // 次要文字
    var textTer: Color { get }       // 辅助文字
    var textMuted: Color { get }     // 最弱文字

    var divider: Color { get }       // 分隔线
    var dividerStrong: Color { get } // 较深分隔

    var chipBg: Color { get }        // chip 默认底
    var chipBgActive: Color { get }  // chip 按下/激活底

    var overlay: Color { get }       // 模态遮罩
    var tabBarBg: Color { get }      // tab bar 底
    var shadowCard: ThemeShadow { get } // 卡片阴影

    // 品牌色派生：fill 两模式相同；text 在浅色模式必须用 *Text 变体保证可读。
    var brand: Color { get }         // 品牌填充色（黄色播放按钮 bg 等）
    var brandText: Color { get }     // 品牌文字色（序号 / 字幕 active 词等）
    var ai: Color { get }            // AI 填充色
    var aiText: Color { get }        // AI 文字色
}

/// 深色主题。
struct DarkTokens: ThemeTokens {
    let bg            = Color(hex: 0x0A0A0C)
    let surface       = Color(hex: 0xFFFFFF, opacity: 0.04)
    let surfaceSubtle = Color(hex: 0xFFFFFF, opacity: 0.025)
    let surfaceElev   = Color(hex: 0x141418, opacity: 0.97)

    let text      = Color(hex: 0xFFFFFF)
    let textSec   = Color(hex: 0xFFFFFF, opacity: 0.62)
    let textTer   = Color(hex: 0xFFFFFF, opacity: 0.42)
    let textMuted = Color(hex: 0xFFFFFF, opacity: 0.28)

    let divider       = Color(hex: 0xFFFFFF, opacity: 0.06)
    let dividerStrong = Color(hex: 0xFFFFFF, opacity: 0.12)

    let chipBg       = Color(hex: 0xFFFFFF, opacity: 0.06)
    let chipBgActive = Color(hex: 0xFFFFFF, opacity: 0.10)

    let overlay  = Color(hex: 0x000000, opacity: 0.5)
    let tabBarBg = Color(hex: 0x0A0A0C, opacity: 0.82)
    let shadowCard = ThemeShadow(color: Color(hex: 0x000000, opacity: 0.55), radius: 32, x: 0, y: 8)

    let brand     = Color(hex: 0xFFE066)
    let brandText = Color(hex: 0xFFE066)
    let ai        = Color(hex: 0xB8C4FF)
    let aiText    = Color(hex: 0xB8C4FF)
}

/// 浅色主题。
struct LightTokens: ThemeTokens {
    let bg            = Color(hex: 0xF4F1EC)
    let surface       = Color(hex: 0xFFFFFF)
    let surfaceSubtle = Color(hex: 0x0A0A0C, opacity: 0.025)
    let surfaceElev   = Color(hex: 0xFFFFFF)

    let text      = Color(hex: 0x0A0A0C)
    let textSec   = Color(hex: 0x0A0A0C, opacity: 0.62)
    let textTer   = Color(hex: 0x0A0A0C, opacity: 0.42)
    let textMuted = Color(hex: 0x0A0A0C, opacity: 0.25)

    let divider       = Color(hex: 0x0A0A0C, opacity: 0.08)
    let dividerStrong = Color(hex: 0x0A0A0C, opacity: 0.16)

    let chipBg       = Color(hex: 0x0A0A0C, opacity: 0.045)
    let chipBgActive = Color(hex: 0x0A0A0C, opacity: 0.10)

    let overlay  = Color(hex: 0x000000, opacity: 0.35)
    let tabBarBg = Color(hex: 0xF4F1EC, opacity: 0.85)
    let shadowCard = ThemeShadow(color: Color(hex: 0x000000, opacity: 0.10), radius: 22, x: 0, y: 6)

    let brand     = Color(hex: 0xFFE066)
    let brandText = Color(hex: 0xA57400)
    let ai        = Color(hex: 0xB8C4FF)
    let aiText    = Color(hex: 0x4054C2)
}

// MARK: - EnvironmentKey 注入

private struct ThemeTokensKey: EnvironmentKey {
    static let defaultValue: ThemeTokens = DarkTokens()
}

extension EnvironmentValues {
    /// 当前主题 token。顶层由 `ThemeProvider` 注入；其余视图用 `@Environment(\.theme)` 读取。
    var theme: ThemeTokens {
        get { self[ThemeTokensKey.self] }
        set { self[ThemeTokensKey.self] = newValue }
    }
}

/// 顶层主题容器：读取 `@AppStorage("theme")` 的三档设置，结合系统深浅，
/// 把对应的 `ThemeTokens` 注入环境，并同步 `preferredColorScheme`（让键盘等系统控件一致）。
/// 用法：`ThemeProvider { RootView() }`。
struct ThemeProvider<Content: View>: View {
    @AppStorage("theme") private var modeRaw: String = ThemeMode.system.rawValue
    @Environment(\.colorScheme) private var systemScheme

    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    private var mode: ThemeMode { ThemeMode(rawValue: modeRaw) ?? .system }

    /// 强制的配色（`dark`/`light` 两档）；`system` 返回 nil = 不干预，交回系统。
    /// 关键：`system` 档绝不能输出 `.preferredColorScheme`，否则它会反向覆盖
    /// 本视图读的 `@Environment(\.colorScheme)`，形成自锁、永远跟不上设备深浅。
    private var forcedScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .dark:   return .dark
        case .light:  return .light
        }
    }

    /// 最终是否深色：`system` 跟随设备，其余两档强制。
    private var resolvedDark: Bool {
        switch mode {
        case .system: return systemScheme == .dark
        case .dark:   return true
        case .light:  return false
        }
    }

    var body: some View {
        let tokens: ThemeTokens = resolvedDark ? DarkTokens() : LightTokens()
        content()
            .environment(\.theme, tokens)
            .preferredColorScheme(forcedScheme)
        // 注：README 要求切换时用 withAnimation(.easeInOut(duration: 0.32)) 包住 —
        // 等后续加「System / Dark / Light」设置入口时，在那个 toggle 处包动画。
    }
}
