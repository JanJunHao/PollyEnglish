import Foundation
import SwiftData

/// 观看事件。每次用户进入播放器都更新一条（按 videoId 合并），不分场次记。
/// 用途：首页推荐排序的「最近观看 / 完成率」信号源。
@Model
final class WatchEvent {
    @Attribute(.unique) var videoId: String
    var lastWatchedAt: Date
    var lastPositionSeconds: Double   // 上次退出时的播放点
    var maxCompletionRatio: Double    // 历史最大完成度，0...1
    var openCount: Int                // 累计打开次数（弱信号：>1 表示用户回来过）

    init(
        videoId: String,
        lastWatchedAt: Date = Date(),
        lastPositionSeconds: Double = 0,
        maxCompletionRatio: Double = 0,
        openCount: Int = 1
    ) {
        self.videoId = videoId
        self.lastWatchedAt = lastWatchedAt
        self.lastPositionSeconds = lastPositionSeconds
        self.maxCompletionRatio = maxCompletionRatio
        self.openCount = openCount
    }
}
