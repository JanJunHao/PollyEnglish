import Foundation
import AVFoundation

#if canImport(WhisperKit)
import WhisperKit
#endif

/// 本地字幕生成服务：
/// - 输入：本地视频文件 URL
/// - 输出：Polly SubtitleDocument JSON（写到磁盘，路径返回）
///
/// 实现：WhisperKit on-device。模型默认下 tiny（80MB），首次跑要拉模型。
/// 不可用时（无 WhisperKit / 非 A16+ 设备）抛 unavailable。
@MainActor
enum LocalSubtitleService {
    enum ServiceError: LocalizedError {
        case unavailable(String)
        case extractAudioFailed(String)
        case transcribeFailed(String)

        var errorDescription: String? {
            switch self {
            case .unavailable(let m): return "本地字幕生成不可用：\(m)"
            case .extractAudioFailed(let m): return "音频提取失败：\(m)"
            case .transcribeFailed(let m): return "转录失败：\(m)"
            }
        }
    }

    /// 入口：给定本地视频 URL，生成 SubtitleDocument JSON 写到 outURL，返回 segments 数量。
    /// progress 回调用于 UI 上展示「转录中… 38%」。
    static func transcribe(
        videoURL: URL,
        outURL: URL,
        videoId: String,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws -> Int {
        #if canImport(WhisperKit)
        // 1) 抽音频（WhisperKit 需要 PCM 或 wav 输入）
        let audioURL = try await extractAudio(from: videoURL)
        defer { try? FileManager.default.removeItem(at: audioURL) }

        progress(0.1)

        // 2) 初始化 WhisperKit（首次 download 模型）。
        let pipe = try await WhisperKit(
            WhisperKitConfig(model: "tiny", verbose: false, logLevel: .error)
        )

        progress(0.3)

        // 3) 跑转录
        let results = try await pipe.transcribe(audioPath: audioURL.path)

        progress(0.9)

        // 4) 拼成 Polly SubtitleDocument
        var segments: [[String: Any]] = []
        var idx = 0
        for r in results {
            for seg in r.segments {
                segments.append([
                    "id": idx,
                    "start": Double(seg.start),
                    "end": Double(seg.end),
                    "text": seg.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    "words": []
                ])
                idx += 1
            }
        }
        let doc: [String: Any] = [
            "video_id": videoId,
            "language": results.first?.language ?? "en",
            "segments": segments
        ]
        let data = try JSONSerialization.data(withJSONObject: doc, options: [.prettyPrinted])
        try data.write(to: outURL, options: .atomic)
        progress(1.0)
        return segments.count
        #else
        throw ServiceError.unavailable("WhisperKit SPM 未集成；project.yml 添加后重 build")
        #endif
    }

    /// 用 AVAssetExportSession 抽 m4a。WhisperKit 内部会再走自己的解码。
    private static func extractAudio(from videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw ServiceError.extractAudioFailed("AVAssetExportSession init nil")
        }
        exporter.outputFileType = .m4a
        exporter.outputURL = outURL

        return try await withCheckedThrowingContinuation { cont in
            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed:
                    cont.resume(returning: outURL)
                case .failed, .cancelled:
                    cont.resume(throwing: ServiceError.extractAudioFailed(
                        exporter.error?.localizedDescription ?? "unknown"
                    ))
                default:
                    cont.resume(throwing: ServiceError.extractAudioFailed("status \(exporter.status.rawValue)"))
                }
            }
        }
    }
}
