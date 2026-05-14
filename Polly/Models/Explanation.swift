import Foundation

/// AI 讲解响应（与文档 04.11 严格 JSON 输出对应）。
struct ExplanationResult: Codable, Identifiable, Hashable {
    var id: String { sentence + (cultural_note ?? "") }

    let sentence: String                  // 原句
    let natural_translation: String       // 地道翻译
    let core_explanation: String          // 核心讲解（1-2 句话讲透）
    let key_vocab: [VocabItem]            // 关键词汇
    let grammar_point: String?            // 语法点（可空）
    let cultural_note: String?            // 文化背景（可空）
    let pronunciation_tip: String?        // 连读/重音 tip（可空）
    let similar_expressions: [String]?    // 类似表达

    struct VocabItem: Codable, Hashable {
        let word: String
        let meaning: String
        let register: String?
        let examples: [String]?
    }
}
