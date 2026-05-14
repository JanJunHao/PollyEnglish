import Foundation
import SwiftData

/// 生词本条目（SwiftData @Model）。
/// 一个单词在一个视频中查询过一次就是一条记录；同词不同视频/不同上下文 = 多条。
@Model
final class VocabularyItem {
    @Attribute(.unique) var id: UUID
    var word: String           // 原词形（用户点击时的形态）
    var lemma: String          // 词形还原后
    var phonetic: String?
    var meanings: [String]     // 释义合并文本（"n. 声音；嗓音 / v. 表达"）
    var contextSentence: String?
    var sourceVideoId: String?
    var sourceVideoTitle: String?
    var createdAt: Date
    /// 学习状态：new / learning / mastered
    var status: String

    init(
        id: UUID = UUID(),
        word: String,
        lemma: String,
        phonetic: String? = nil,
        meanings: [String] = [],
        contextSentence: String? = nil,
        sourceVideoId: String? = nil,
        sourceVideoTitle: String? = nil,
        createdAt: Date = Date(),
        status: String = "new"
    ) {
        self.id = id
        self.word = word
        self.lemma = lemma
        self.phonetic = phonetic
        self.meanings = meanings
        self.contextSentence = contextSentence
        self.sourceVideoId = sourceVideoId
        self.sourceVideoTitle = sourceVideoTitle
        self.createdAt = createdAt
        self.status = status
    }
}
