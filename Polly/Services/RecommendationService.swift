import Foundation
import SwiftData

/// 首页推荐排序。把视频按"编辑权重 + 观看历史信号"打分排序。
///
/// 算法（朴素加权）：
/// - editorial: isRecommended 命中 +10（运营首推）
/// - novelty: 没看过的内容 +2（默认偏向新东西）
/// - continuation: 看过但未完成（completion < 0.85） +6（鼓励继续学）
/// - completion penalty: 完成度 ≥ 0.85 一律 -8（看完的就别老在首页）
/// - recency: 最近 24h 内打开过 +3（用户在追这个内容池）
/// - tiny jitter: ±0.5 防止同分内容首页永远同序
///
/// 输入 watchByVideoId 来自 SwiftData @Query of WatchEvent。
/// 不在这层做 IO；调用方负责把 @Query 结果传进来。
enum RecommendationService {
    struct Score {
        let video: DemoVideo
        let value: Double
        let reason: String  // 调试用，肉眼看排序依据
    }

    static func rank(
        videos: [DemoVideo],
        watches: [WatchEvent]
    ) -> [Score] {
        let watchByVideoId = Dictionary(uniqueKeysWithValues: watches.map { ($0.videoId, $0) })
        let now = Date()

        return videos
            .map { v -> Score in
                var score: Double = 0
                var reasons: [String] = []

                if v.isRecommended {
                    score += 10
                    reasons.append("edt")
                }

                if let w = watchByVideoId[v.id] {
                    let hoursAgo = now.timeIntervalSince(w.lastWatchedAt) / 3600.0
                    if hoursAgo < 24 {
                        score += 3
                        reasons.append("rec24h")
                    }
                    if w.maxCompletionRatio >= 0.85 {
                        score -= 8
                        reasons.append("done")
                    } else if w.maxCompletionRatio > 0 {
                        score += 6
                        reasons.append("cont")
                    }
                } else {
                    score += 2
                    reasons.append("new")
                }

                score += Double.random(in: -0.5...0.5)

                return Score(video: v, value: score, reason: reasons.joined(separator: "+"))
            }
            .sorted { $0.value > $1.value }
    }

    /// 简便接口：只要排好的视频。
    static func rankedVideos(videos: [DemoVideo], watches: [WatchEvent]) -> [DemoVideo] {
        rank(videos: videos, watches: watches).map { $0.video }
    }
}

/// 写入侧 helper：从 Player 退出时更新 WatchEvent。
@MainActor
enum WatchHistoryTracker {
    /// 记录一次观看。重复 videoId 会更新而不是插新。
    static func record(
        videoId: String,
        positionSeconds: Double,
        durationSeconds: Double,
        in context: ModelContext
    ) {
        let completion = durationSeconds > 0
            ? min(1.0, max(0, positionSeconds / durationSeconds))
            : 0

        let fetch = FetchDescriptor<WatchEvent>(
            predicate: #Predicate { $0.videoId == videoId }
        )
        do {
            if let existing = try context.fetch(fetch).first {
                existing.lastWatchedAt = Date()
                existing.lastPositionSeconds = positionSeconds
                existing.maxCompletionRatio = max(existing.maxCompletionRatio, completion)
                existing.openCount += 1
            } else {
                let event = WatchEvent(
                    videoId: videoId,
                    lastPositionSeconds: positionSeconds,
                    maxCompletionRatio: completion,
                    openCount: 1
                )
                context.insert(event)
            }
            try context.save()
        } catch {
            print("[WatchHistoryTracker] save failed: \(error)")
        }
    }
}
