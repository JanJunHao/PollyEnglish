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
///
/// `id` 用 `original + contextSentence` 而不是 `UUID()`，是为了让 `.sheet(item:)` 在同一次查词的
/// 两阶段（本地词典命中 → AI 兜底结果）之间保持同一个 identity，不会出现「先弹个 loading 又关掉再弹」的闪。
struct WordLookupResult: Identifiable, Hashable {
    let original: String          // 用户点击的原文形式（如 "running" / "dreams"）
    let lemma: String             // 词形还原后（"run" / "dream"）
    let entry: WordEntry?         // 词典查得；nil = 未收录
    let contextSentence: String?  // 出现的句子（用于例句展示）

    var id: String { original + "|" + (contextSentence ?? "") }
}
