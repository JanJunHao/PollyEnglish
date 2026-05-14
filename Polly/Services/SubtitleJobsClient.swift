import Foundation

/// 字幕生成任务客户端。对接 polly-server `/v1/subtitles/jobs`。
///
/// Flow：
/// 1. `submit(youtubeId:)` POST 任务 → 返回 pending/running 状态 job
/// 2. `pollUntilDone(id:)` 轮询直到 done / failed / 超时
/// 3. 成功后 `job.result_subtitle_url` 是 SubtitleDocument JSON 的可拉取 URL
@MainActor
final class SubtitleJobsClient {
    static let shared = SubtitleJobsClient()
    private init() {}

    struct CreateBody: Encodable {
        let youtube_id: String
        let target_video_id: String?
    }

    /// 提交一个生成任务。
    func submit(youtubeId: String, targetVideoId: String? = nil) async throws -> SubtitleJob {
        try await PollyAPIClient.shared.post(
            "v1/subtitles/jobs",
            body: CreateBody(youtube_id: youtubeId, target_video_id: targetVideoId)
        )
    }

    /// 查询单个任务当前状态。
    func status(id: String) async throws -> SubtitleJob {
        try await PollyAPIClient.shared.get("v1/subtitles/jobs/\(id)")
    }

    /// 轮询直到终态或超时。
    /// - Parameters:
    ///   - id: job id
    ///   - interval: 轮询间隔（秒），默认 2s
    ///   - timeout: 总超时（秒），默认 180s（YT 自动字幕拉取通常 10–30s 完成；Whisper 较慢）
    func pollUntilDone(
        id: String,
        interval: TimeInterval = 2,
        timeout: TimeInterval = 180
    ) async throws -> SubtitleJob {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            let job = try await status(id: id)
            if job.isTerminal { return job }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        throw SubtitleJobError.timeout
    }
}

enum SubtitleJobError: LocalizedError {
    case timeout
    case failed(String?)

    var errorDescription: String? {
        switch self {
        case .timeout: return "字幕生成超时"
        case .failed(let m): return "字幕生成失败：\(m ?? "未知原因")"
        }
    }
}
