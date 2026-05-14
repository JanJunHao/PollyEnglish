import Foundation
import NaturalLanguage

/// 离线词典服务。
/// 设计目标（文档 03.12）：
/// - 单词点击到卡片显示 < 80ms
/// - 词典启动时全量加载到内存哈希表，查询 O(1)
/// - 词形还原用 Apple NLTagger（lemma scheme）
///
/// 本周用一份 80 词的精简 JSON 跑通整条链路；
/// 上线前替换为 ECDICT/柯林斯/牛津（详见 plan）。
@MainActor
final class DictionaryService {
    static let shared = DictionaryService()

    private var db: [String: WordEntry] = [:]
    private(set) var isReady: Bool = false

    private init() {
        loadFromBundle()
    }

    // MARK: - Load

    private func loadFromBundle() {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
            print("Dictionary words.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: WordEntry].self, from: data)
            // 全部 key 转小写存哈希表，查询时也走小写
            db = Dictionary(uniqueKeysWithValues: decoded.map { ($0.key.lowercased(), $0.value) })
            isReady = true
        } catch {
            print("Dictionary load failed: \(error)")
        }
    }

    // MARK: - Lookup

    /// 内存 AI 查词缓存（key 用小写 lemma），跨会话内复用
    private var aiCache: [String: WordEntry] = [:]

    /// 单词查询：依次尝试原词 → lemma 还原 → lowercased 原词 → AI 缓存。
    /// AI 实时查询是 async，调用 `aiLookup(...)` 获取。
    func lookup(_ word: String, contextSentence: String? = nil) -> WordLookupResult {
        let cleaned = clean(word)
        let lemma = lemmatize(cleaned)

        let entry = db[cleaned.lowercased()]
            ?? db[lemma.lowercased()]
            ?? aiCache[lemma.lowercased()]
            ?? aiCache[cleaned.lowercased()]

        return WordLookupResult(
            original: cleaned,
            lemma: lemma,
            entry: entry,
            contextSentence: contextSentence
        )
    }

    /// AI 实时查词。未命中本地词典时调用，结果写入 aiCache。
    /// 走 polly-server /v1/ai/word（服务端再选模型 + 持 key）。
    func aiLookup(word: String, context: String?) async throws -> WordEntry {
        let cleaned = clean(word)
        let lemma = lemmatize(cleaned)

        // 先查 AI 缓存
        if let cached = aiCache[lemma.lowercased()] ?? aiCache[cleaned.lowercased()] {
            return cached
        }

        struct WordRequest: Encodable {
            let word: String
            let context: String?
        }
        struct WordResponse: Decodable {
            let word: String
            let phonetic: String
            let level: String
            let definitions: [WordDefinition]
            let model: String
            let cached: Bool
        }

        let resp: WordResponse = try await PollyAPIClient.shared.post(
            "v1/ai/word",
            body: WordRequest(word: cleaned, context: context)
        )

        let entry = WordEntry(
            phonetic: resp.phonetic,
            level: resp.level,
            definitions: resp.definitions
        )

        // 缓存到 lemma 和原词形两个 key
        aiCache[lemma.lowercased()] = entry
        aiCache[cleaned.lowercased()] = entry

        return entry
    }

    // MARK: - Word Processing

    /// 词边界清洗：剔除前后标点 / 引号 / 括号（文档 03.15）。
    /// 保留 isn't / can't 这类缩写，保留连字符 well-known，保留 COVID-19。
    private func clean(_ raw: String) -> String {
        let trimSet = CharacterSet.punctuationCharacters
            .union(.whitespaces)
            .subtracting(CharacterSet(charactersIn: "'-")) // 保留 ' 和 -
        return raw.trimmingCharacters(in: trimSet)
    }

    /// Apple NLTagger lemma 词形还原。
    /// running → run, children → child, better → good
    private func lemmatize(_ word: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = word
        let range = word.startIndex..<word.endIndex
        var result = word
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: [.omitWhitespace, .omitPunctuation]) { tag, _ in
            if let lemma = tag?.rawValue, !lemma.isEmpty {
                result = lemma
            }
            return false  // 只取第一个
        }
        return result
    }
}
