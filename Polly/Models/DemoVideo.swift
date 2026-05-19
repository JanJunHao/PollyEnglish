import SwiftUI

/// 视频元信息。所有视频走 native 播放（AVPlayer + 自托管 mp4）。
struct DemoVideo: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let source: String
    let durationSeconds: Int
    let cefrLevel: String        // A2 / B1 / B2 / C1
    let thumbnailName: String?   // bundle 内图片名；纯远端视频为 nil（走 thumbnailURL）
    let categoryColorHex: UInt32 // 列表卡左上角分类圆点
    let isRecommended: Bool      // 首页 Banner 显示
    let categories: [VideoCategory]  // 一个视频可归多个模块
    var thumbnailURL: String? = nil          // 远端缩略图 URL；nil 则回退到 bundle 的 thumbnailName
    var videoURL: String? = nil              // 远端 mp4 URL（NASA / IA / VOA）；nil 则按 id 找 bundle 内 mp4
    var subtitleURL: String? = nil           // 远端字幕 JSON URL（SubtitleDocument 格式）；nil 则查 bundle demo-<id>.json
    var updatedAt: Date = .distantPast       // 服务端 updated_at；用于「最近更新」混合 feed 排序

    var categoryColor: Color { Color(hex: categoryColorHex) }

    var durationDisplay: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

extension DemoVideo {
    /// 仅供 SwiftUI Preview 使用的样例数据。运行时内容一律来自 ContentService。
    static let all: [DemoVideo] = [
        DemoVideo(
            id: "preview-sample",
            title: "Sample Video for Previews",
            author: "Polly",
            source: "Preview",
            durationSeconds: 5 * 60,
            cefrLevel: "B1",
            thumbnailName: nil,
            categoryColorHex: 0x4ECDC4,
            isRecommended: true,
            categories: [.discovery]
        )
    ]
}

/// 远端缩略图的进程内解码缓存。
/// AsyncImage 不缓存：卡片滑出再滑回会从 .empty 重新加载，闪一下方块占位。
/// 这里缓存「已解码的 UIImage」，滑回时同步命中、零闪烁。
enum ThumbnailCache {
    static let shared: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.countLimit = 200          // 最多缓存 200 张缩略图
        return c
    }()
}

/// 缩略图视图，三种状态各有专属占位，避免「加载失败」和「加载中」糊成一片黑底：
/// - 加载中：纯色 + 转圈
/// - 加载失败 / 无图：兜底图（深色渐变 + 居中 film 图标）
/// - 成功：远端图片
/// name 是 bundle 内本地图（demo 期遗留），有则优先用本地图避免任何网络等待。
struct ThumbnailImage: View {
    let name: String?
    var url: String? = nil

    var body: some View {
        if let n = name, let ui = Self.bundleUIImage(n) {
            Image(uiImage: ui).resizable()
        } else if let raw = url, let parsed = URL(string: raw) {
            CachedRemoteThumbnail(url: parsed)
        } else {
            ThumbnailFallback()
        }
    }

    private static func bundleUIImage(_ n: String) -> UIImage? {
        UIImage(named: "\(n).jpg") ?? UIImage(named: "\(n).png") ?? UIImage(named: n)
    }
}

/// 带缓存的远端缩略图。命中缓存时同步渲染，不经过 loading 占位，消除「滑回闪方块」。
private struct CachedRemoteThumbnail: View {
    let url: URL
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        // 每次渲染先同步查一次缓存：滑回时 @State 虽被重建，缓存仍在 → 直接出图。
        let cached = image ?? ThumbnailCache.shared.object(forKey: url as NSURL)
        Group {
            if let ui = cached {
                Image(uiImage: ui).resizable()
            } else if failed {
                ThumbnailFallback()
            } else {
                ThumbnailLoading()
            }
        }
        .task(id: url) {
            if cached != nil { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let ui = UIImage(data: data) else { failed = true; return }
                ThumbnailCache.shared.setObject(ui, forKey: url as NSURL)
                image = ui
            } catch is CancellationError {
                // 滑动中取消属正常，不算失败
            } catch {
                failed = true
            }
        }
    }
}

private struct ThumbnailLoading: View {
    var body: some View {
        ZStack {
            AppColors.bgElevated
            ProgressView()
                .tint(AppColors.textTertiary)
        }
    }
}

/// 封面缺失 / 加载失败的兜底图。做成有设计感的占位，而不是一块黑。
private struct ThumbnailFallback: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.bgElevated, AppColors.bgPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "film")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(AppColors.textTertiary.opacity(0.6))
        }
    }
}
