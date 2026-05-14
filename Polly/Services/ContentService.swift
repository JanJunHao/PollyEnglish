import Foundation

/// 内容服务：拉取 polly-server 的 manifest，失败时回退到 bundle 内 DemoVideo.all。
///
/// 当前简化策略：DemoVideo 仍是 UI 主模型，远端 ContentDTO 仅用来 (a) 决定首页显示哪些视频
/// (b) 后期带 video_url / subtitle_url 等远端资源。本地 3 个 demo 的缩略图/视频/字幕都还在 bundle 里，
/// remote slug 与 bundle 内 thumbnailName / 字幕文件名一一对应。
@MainActor
final class ContentService: ObservableObject {
    static let shared = ContentService()

    @Published private(set) var videos: [DemoVideo]
    @Published private(set) var lastSync: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var isFromServer: Bool = false

    private let bundleVideos: [DemoVideo]

    private init() {
        let loaded = Self.loadBundleManifest() ?? DemoVideo.all
        self.bundleVideos = loaded
        self.videos = loaded
    }

    /// 启动时尝试从 bundle 内 manifest.json 加载；失败则回退到 DemoVideo.all 硬编码。
    /// Phase A：开发期内容由 manifest.json 维护，避免改一处视频元信息要改两处代码。
    private static func loadBundleManifest() -> [DemoVideo]? {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        do {
            let decoded = try JSONDecoder().decode(BundleManifest.self, from: data)
            return decoded.contents.map { item in
                DemoVideo(
                    id: item.id,
                    title: item.title,
                    author: item.author,
                    source: item.source,
                    durationSeconds: item.duration_seconds,
                    cefrLevel: item.cefr_level,
                    thumbnailName: item.thumbnail_name,
                    categoryColorHex: UInt32(item.category_color_hex),
                    isRecommended: item.is_recommended,
                    categories: item.categories.compactMap { VideoCategory(rawValue: $0) },
                    playMode: VideoPlayMode(rawValue: item.play_mode) ?? .native,
                    youtubeId: item.youtube_id
                )
            }
        } catch {
            print("[ContentService] bundle manifest decode failed: \(error)")
            return nil
        }
    }

    /// 从服务端增量拉取；网络失败保留 bundle fallback。
    func refresh(since: Date? = nil) async {
        do {
            var query: [URLQueryItem] = []
            if let since {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                query.append(URLQueryItem(name: "since", value: iso.string(from: since)))
            }
            let resp: ContentsLatestResponse = try await PollyAPIClient.shared.get(
                "v1/contents/latest", query: query
            )

            // 服务端没返回任何视频时（如 since 太晚），保留现有列表
            let merged = ContentService.merge(remote: resp.contents, bundle: bundleVideos)
            self.videos = merged
            self.lastSync = resp.server_time
            self.lastError = nil
            self.isFromServer = true
        } catch {
            // 网络/解析失败：保留 bundle 兜底，记录错误
            let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            print("[ContentService] refresh failed: \(msg)")
            self.lastError = msg
            self.isFromServer = false
        }
    }

    /// 把远端 ContentDTO 合并到 [DemoVideo]。
    /// 同 id 优先用远端元信息，缩略图 / source 等使用本地映射保持 UI 视觉一致。
    /// 远端没有但 bundle 有的（如新 demo 还没入库），保留 bundle 项。
    private static func merge(remote: [ContentDTO], bundle: [DemoVideo]) -> [DemoVideo] {
        let bundleById = Dictionary(uniqueKeysWithValues: bundle.map { ($0.id, $0) })
        let remoteIds = Set(remote.map { $0.id })

        var result: [DemoVideo] = []
        for dto in remote {
            // bundle://... 是 ingest 期没真上传时的占位前缀，UI 应忽略
            let remoteThumb: String? = dto.thumbnail_url.hasPrefix("http") ? dto.thumbnail_url : nil

            let mode = VideoPlayMode(rawValue: dto.play_mode) ?? .native
            if let local = bundleById[dto.id] {
                // bundle 有同 id：用 bundle 缩略图 + 配色（视觉一致）
                result.append(DemoVideo(
                    id: dto.id,
                    title: dto.title,
                    author: dto.author,
                    source: dto.source,
                    durationSeconds: dto.duration_seconds,
                    cefrLevel: dto.cefr_level,
                    thumbnailName: local.thumbnailName,
                    categoryColorHex: local.categoryColorHex,
                    isRecommended: dto.is_recommended,
                    categories: dto.categories.compactMap { VideoCategory(rawValue: $0) },
                    playMode: mode,
                    youtubeId: dto.youtube_id,
                    thumbnailURL: remoteThumb,
                    subtitleURL: dto.subtitle_url
                ))
            } else {
                // 纯远端视频（TED youtube_embed / NASA / IA native）
                result.append(DemoVideo(
                    id: dto.id,
                    title: dto.title,
                    author: dto.author,
                    source: dto.source,
                    durationSeconds: dto.duration_seconds,
                    cefrLevel: dto.cefr_level,
                    thumbnailName: nil,
                    categoryColorHex: UInt32(dto.category_color_hex),
                    isRecommended: dto.is_recommended,
                    categories: dto.categories.compactMap { VideoCategory(rawValue: $0) },
                    playMode: mode,
                    youtubeId: dto.youtube_id,
                    thumbnailURL: remoteThumb,
                    videoURL: dto.video_url,
                    subtitleURL: dto.subtitle_url
                ))
            }
        }
        // bundle 有但远端没返回的（如 since 增量拉取）：保留旧的
        for v in bundle where !remoteIds.contains(v.id) && !result.contains(where: { $0.id == v.id }) {
            result.append(v)
        }
        return result
    }
}

// MARK: - 反馈

extension ContentService {
    enum FeedbackKind: String {
        case wrongCategory = "wrong_category"
        case poorAudio = "poor_audio"
        case poorVideo = "poor_video"
        case wrongSubtitle = "wrong_subtitle"
        case other
    }

    struct FeedbackResult: Decodable {
        let accepted: Bool
        let feedback_count: Int
        let status: String
    }

    /// 提交内容反馈到 polly-server。返回 nil 表示网络/接口失败（不阻塞 UI）。
    func submitFeedback(videoID: String, kind: FeedbackKind, note: String? = nil) async -> FeedbackResult? {
        struct Body: Encodable { let kind: String; let note: String? }
        do {
            return try await PollyAPIClient.shared.post(
                "v1/contents/\(videoID)/feedback",
                body: Body(kind: kind.rawValue, note: note)
            )
        } catch {
            print("[ContentService] feedback failed: \(error)")
            return nil
        }
    }
}

// MARK: - DTOs (与 polly-server/app/schemas.py 对齐)

private struct ContentsLatestResponse: Decodable {
    let server_time: Date
    let version: Int
    let contents: [ContentDTO]
}

// MARK: - Bundle manifest.json

private struct BundleManifest: Decodable {
    let version: Int
    let contents: [BundleContent]
}

private struct BundleContent: Decodable {
    let id: String
    let title: String
    let author: String
    let source: String
    let duration_seconds: Int
    let cefr_level: String
    let thumbnail_name: String
    let category_color_hex: Int
    let is_recommended: Bool
    let categories: [String]
    let play_mode: String
    let youtube_id: String?
}

struct ContentDTO: Decodable {
    let id: String
    let title: String
    let author: String
    let source: String
    let duration_seconds: Int
    let cefr_level: String
    let play_mode: String
    let video_url: String?
    let youtube_id: String?
    let thumbnail_url: String
    let subtitle_url: String?
    let vocabulary_url: String?
    let explanation_url: String?
    let categories: [String]
    let category_color_hex: Int
    let is_recommended: Bool
    let updated_at: Date
}
