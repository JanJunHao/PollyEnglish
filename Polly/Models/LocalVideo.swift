import Foundation
import SwiftData

/// 用户从设备相册或文件 app 导入的视频。文件存 Application Support / LocalVideos，
/// 字幕生成完成后写到同目录的 .subtitle.json。
@Model
final class LocalVideo {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var fileRelativePath: String   // 相对 Application Support 的路径，便于沙盒迁移
    var durationSeconds: Double
    var importedAt: Date
    /// 字幕生成状态：pending / running / done / failed
    var subtitleStatus: String
    var subtitleRelativePath: String?
    var subtitleSegmentCount: Int?
    var subtitleError: String?

    init(
        id: UUID = UUID(),
        displayName: String,
        fileRelativePath: String,
        durationSeconds: Double = 0,
        importedAt: Date = Date(),
        subtitleStatus: String = "pending",
        subtitleRelativePath: String? = nil,
        subtitleSegmentCount: Int? = nil,
        subtitleError: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.fileRelativePath = fileRelativePath
        self.durationSeconds = durationSeconds
        self.importedAt = importedAt
        self.subtitleStatus = subtitleStatus
        self.subtitleRelativePath = subtitleRelativePath
        self.subtitleSegmentCount = subtitleSegmentCount
        self.subtitleError = subtitleError
    }
}

extension LocalVideo {
    static func applicationSupportRoot() -> URL {
        // Application Support 永久保留、iCloud 不备份；本地导入视频放这。
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let base = urls[0].appendingPathComponent("LocalVideos", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    var fileURL: URL {
        Self.applicationSupportRoot().appendingPathComponent(fileRelativePath)
    }

    var subtitleURL: URL? {
        guard let p = subtitleRelativePath else { return nil }
        return Self.applicationSupportRoot().appendingPathComponent(p)
    }
}
