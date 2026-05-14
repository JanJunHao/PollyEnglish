import Foundation
import SwiftData

/// 收藏的句子（独立于生词本 VocabularyItem）。
/// 一个视频里收藏多少句就有多少条。
@Model
final class SentenceFavorite {
    @Attribute(.unique) var id: UUID
    var videoId: String
    var segmentId: Int
    var text: String
    var translation: String?
    var videoTitle: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        videoId: String,
        segmentId: Int,
        text: String,
        translation: String? = nil,
        videoTitle: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.videoId = videoId
        self.segmentId = segmentId
        self.text = text
        self.translation = translation
        self.videoTitle = videoTitle
        self.createdAt = createdAt
    }
}
