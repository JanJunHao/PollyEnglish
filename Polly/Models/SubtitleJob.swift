import Foundation

/// 字幕生成任务（运行时流水线）。与 polly-server/app/schemas.py::SubtitleJobOut 对齐。
struct SubtitleJob: Codable, Identifiable, Equatable {
    let id: String
    let youtube_id: String?
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
            self = Status(rawValue: raw) ?? .unknown
        }
    }

    var isTerminal: Bool { status == .done || status == .failed }
}
