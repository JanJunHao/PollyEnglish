import Foundation

/// 字幕翻译任务客户端。对接 polly-server `/v1/translations/jobs`。
///
/// 用途：把 SubtitleJob 跑出来的英文字幕翻成 zh-CN，结果 JSON 内每个 segment 多一个 translation 字段。
@MainActor
final class TranslationJobsClient {
    static let shared = TranslationJobsClient()
    private init() {}

    struct CreateBody: Encodable {
        let source_subtitle_url: String
        let target_lang: String
    }

    func submit(sourceSubtitleURL: String, targetLang: String = "zh-CN") async throws -> TranslationJob {
        try await PollyAPIClient.shared.post(
            "v1/translations/jobs",
            body: CreateBody(source_subtitle_url: sourceSubtitleURL, target_lang: targetLang)
        )
    }

    func status(id: String) async throws -> TranslationJob {
        try await PollyAPIClient.shared.get("v1/translations/jobs/\(id)")
    }

    /// 默认 5s 间隔，超时 5 分钟（gpt-4o 翻译 100 句 ~60s，长视频可能更慢）。
    func pollUntilDone(
        id: String,
        interval: TimeInterval = 5,
        timeout: TimeInterval = 300
    ) async throws -> TranslationJob {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            let job = try await status(id: id)
            if job.isTerminal { return job }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        throw TranslationJobError.timeout
    }
}

enum TranslationJobError: LocalizedError {
    case timeout
    case failed(String?)

    var errorDescription: String? {
        switch self {
        case .timeout: return "翻译超时"
        case .failed(let m): return "翻译失败：\(m ?? "未知原因")"
        }
    }
}
