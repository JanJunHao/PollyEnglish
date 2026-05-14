import SwiftUI

/// 播放模式：native 走 AVPlayer + bundle/CDN mp4；youtubeEmbed 走 WKWebView + YouTube iFrame
/// （TED 等 CC-NC 内容合规红线：上架版必须走 youtubeEmbed）
enum VideoPlayMode: String, Codable, Hashable {
    case native
    case youtubeEmbed = "youtube_embed"
}

/// Demo 视频元信息。本周 demo 硬编码 3 个；后续从 manifest.json 加载。
struct DemoVideo: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let source: String           // 来源：TED / TED-Ed
    let durationSeconds: Int
    let cefrLevel: String        // A2 / B1 / B2 / C1
    let thumbnailName: String?   // bundle 内图片名；纯远端视频为 nil（走 thumbnailURL）
    let categoryColorHex: UInt32 // 列表卡左上角分类圆点
    let isRecommended: Bool      // 首页 Banner 显示
    let categories: [VideoCategory]  // 一个视频可归多个模块
    var playMode: VideoPlayMode = .native    // 默认 native；TED 系列在 manifest/server 里覆写
    var youtubeId: String? = nil             // playMode == .youtubeEmbed 时必填
    var thumbnailURL: String? = nil          // 远端缩略图 URL；nil 则回退到 bundle 的 thumbnailName
    var videoURL: String? = nil              // native 模式的远端 mp4 URL（NASA / IA / VOA）；nil 则按 id 找 bundle 内 mp4
    var subtitleURL: String? = nil           // 远端字幕 JSON URL（SubtitleDocument 格式）；nil 则查 bundle demo-<id>.json

    var categoryColor: Color { Color(hex: categoryColorHex) }

    var durationDisplay: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

extension DemoVideo {
    static let all: [DemoVideo] = [
        DemoVideo(
            id: "julian-treasure",
            title: "How to speak so that people want to listen",
            author: "Julian Treasure",
            source: "TED",
            durationSeconds: 9 * 60 + 58,
            cefrLevel: "B2",
            thumbnailName: "julian-treasure-maxresdefault",
            categoryColorHex: 0xFFE066,
            isRecommended: true,
            categories: [.ted, .highlights],
            playMode: .youtubeEmbed,
            youtubeId: "eIho2S0ZahI"
        ),
        DemoVideo(
            id: "ted-ed-dream",
            title: "Why do we dream?",
            author: "TED-Ed",
            source: "TED-Ed",
            durationSeconds: 4 * 60 + 58,
            cefrLevel: "B1",
            thumbnailName: "ted-ed-dream-maxresdefault",
            categoryColorHex: 0xB8C4FF,
            isRecommended: false,
            categories: [.discovery, .ted],
            playMode: .youtubeEmbed,
            youtubeId: "2W85Dwxx218"
        ),
        DemoVideo(
            id: "tim-urban",
            title: "Inside the mind of a master procrastinator",
            author: "Tim Urban",
            source: "TED",
            durationSeconds: 14 * 60 + 4,
            cefrLevel: "C1",
            thumbnailName: "tim-urban-maxresdefault",
            categoryColorHex: 0xFFAC75,
            isRecommended: false,
            categories: [.ted, .highlights],
            playMode: .youtubeEmbed,
            youtubeId: "arj7oStGLkU"
        )
    ]
}

/// 缩略图视图：
/// - name + url 都有：先 bundle 占位，AsyncImage 成功后切远端图（demo 3 视频的体验）
/// - 只有 url：纯远端，loading 用纯色占位（100 条 TED 都是这条路径）
/// - 只有 name：纯本地（保留向后兼容）
/// - 都无：bgElevated 占位
struct ThumbnailImage: View {
    let name: String?
    var url: String? = nil

    var body: some View {
        if let raw = url, let parsed = URL(string: raw) {
            AsyncImage(url: parsed) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                case .empty:
                    loadingPlaceholder
                case .failure:
                    loadingPlaceholder
                @unknown default:
                    loadingPlaceholder
                }
            }
        } else if name != nil {
            bundleImage
        } else {
            Rectangle().fill(AppColors.bgElevated)
        }
    }

    /// 远端加载中 / 失败时占位：有 bundle 兜底用 bundle，没有就 bgElevated。
    @ViewBuilder
    private var loadingPlaceholder: some View {
        if name != nil {
            bundleImage
        } else {
            Rectangle().fill(AppColors.bgElevated)
        }
    }

    @ViewBuilder
    private var bundleImage: some View {
        if let n = name,
           let ui = UIImage(named: "\(n).jpg")
            ?? UIImage(named: "\(n).png")
            ?? UIImage(named: n) {
            Image(uiImage: ui).resizable()
        } else {
            Rectangle().fill(AppColors.bgElevated)
        }
    }
}
