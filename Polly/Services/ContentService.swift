import Foundation

/// 内容服务：拉取 polly-server 的 manifest。
///
/// 数据源策略：唯一来源是服务端。启动时 videos 为空，由 HomeView 的 .task 触发 refresh。
/// 网络失败时 videos 保持上一次成功的快照（首次失败则为空），UI 据此显示网络异常占位图。
/// 本地 bundle 内的缩略图 / 字幕等资源仍按 thumbnailName 命中，但元信息不再做兜底。
@MainActor
final class ContentService: ObservableObject {
    static let shared = ContentService()

    @Published private(set) var videos: [DemoVideo] = []
    @Published private(set) var lastSync: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var isFromServer: Bool = false

    private init() {}

    /// 从服务端拉取内容。失败时保留上一次的 videos 快照（首次失败则为空），由 UI 处理空态。
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

            self.videos = ContentService.mapRemote(resp.contents)
            self.lastSync = resp.server_time
            self.lastError = nil
            self.isFromServer = true
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            print("[ContentService] refresh failed: \(msg)")
            self.lastError = msg
            self.isFromServer = false
        }
    }

    /// 把远端 ContentDTO 映射成 UI 用的 DemoVideo。
    private static func mapRemote(_ remote: [ContentDTO]) -> [DemoVideo] {
        remote.map { dto in
            // bundle://... 是 ingest 期没真上传时的占位前缀，UI 应忽略
            let remoteThumb: String? = dto.thumbnail_url.hasPrefix("http") ? dto.thumbnail_url : nil
            return DemoVideo(
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
                thumbnailURL: remoteThumb,
                videoURL: dto.video_url,
                subtitleURL: dto.subtitle_url,
                updatedAt: dto.updated_at
            )
        }
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

struct ContentDTO: Decodable {
    let id: String
    let title: String
    let author: String
    let source: String
    let duration_seconds: Int
    let cefr_level: String
    let video_url: String?
    let thumbnail_url: String
    let subtitle_url: String?
    let vocabulary_url: String?
    let explanation_url: String?
    let categories: [String]
    let category_color_hex: Int
    let is_recommended: Bool
    let updated_at: Date
}
