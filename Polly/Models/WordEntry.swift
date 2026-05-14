import Foundation

/// 词典里单个词的释义。
struct WordEntry: Codable, Hashable {
    let phonetic: String?
    let level: String?
    let definitions: [WordDefinition]
}

struct WordDefinition: Codable, Hashable {
    let pos: String        // 词性：n. / v. / adj. / adv. / num. / prep. / pron. / conj. ...
    let meaning: String    // 中文释义
}

/// 用户点击单词时的"查询结果"：原词形 + lemma + 词典数据 + 来源上下文。
struct WordLookupResult: Identifiable, Hashable {
    let id = UUID()
    let original: String          // 用户点击的原文形式（如 "running" / "dreams"）
    let lemma: String             // 词形还原后（"run" / "dream"）
    let entry: WordEntry?         // 词典查得；nil = 未收录
    let contextSentence: String?  // 出现的句子（用于例句展示）

    static func == (lhs: WordLookupResult, rhs: WordLookupResult) -> Bool {
        lhs.id == rhs.id
    }
}
