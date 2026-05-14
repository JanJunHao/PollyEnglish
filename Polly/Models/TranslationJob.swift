import Foundation

/// 字幕翻译 job 的客户端镜像（对齐 polly-server schemas.TranslationJobOut）。
struct TranslationJob: Codable, Identifiable, Equatable {
    let id: String
    let source_subtitle_url: String
    let target_lang: String
    let status: Status
    let result_subtitle_url: String?
    let segments_count: Int?
    let error_message: String?
    let created_at: Date
    let updated_at: Date

    enum Status: String, Codable {
        case pending, running, done, failed, unknown

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Self(rawValue: raw) ?? .unknown
        }
    }

    var isTerminal: Bool { status == .done || status == .failed }
}
