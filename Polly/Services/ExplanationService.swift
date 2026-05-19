import Foundation

/// 句子讲解服务：先查内存缓存，未命中时调 polly-server `/v1/ai/explain`。
/// 客户端不再持有任何 LLM key，所有 prompt 和模型选择都在服务端。
@MainActor
final class ExplanationService {
    static let shared = ExplanationService()
    private init() {}

    private var cache: [String: ExplanationResult] = [:]

    func deepExplain(segment: SubtitleSegment,
                     video: DemoVideo) async throws -> ExplanationResult {
        let key = "\(video.id)#\(segment.id)"
        if let cached = cache[key] { return cached }

        let body = ExplainRequest(
            sentence: segment.text,
            video_id: video.id,
            segment_id: segment.id,
            video_title: video.title,
            video_author: video.author,
            video_source: video.source,
            cefr_level: video.cefrLevel,
            context_before: nil,
            context_after: nil
        )

        let resp: ExplainResponse = try await PollyAPIClient.shared.post("v1/ai/explain", body: body)

        let result = ExplanationResult(
            sentence: resp.sentence,
            natural_translation: resp.natural_translation,
            core_explanation: resp.core_explanation,
            key_vocab: resp.key_vocab,
            grammar_point: resp.grammar_point,
            cultural_note: resp.cultural_note,
            pronunciation_tip: resp.pronunciation_tip,
            similar_expressions: resp.similar_expressions
        )
        cache[key] = result
        return result
    }

    /// 外刊整句讲解。复用同一个 `/v1/ai/explain`——文章 id 当 video_id、句序当 segment_id。
    /// 服务端在入库时已按 article_id / 句序预生成讲解缓存，命中即秒回。
    func deepExplain(articleSentence sentence: ArticleSegment,
                     article: Article) async throws -> ExplanationResult {
        let key = "\(article.id)#\(sentence.id)"
        if let cached = cache[key] { return cached }

        let body = ExplainRequest(
            sentence: sentence.text,
            video_id: article.id,
            segment_id: sentence.id,
            video_title: article.title,
            video_author: article.author,
            video_source: article.source,
            cefr_level: article.cefrLevel,
            context_before: nil,
            context_after: nil
        )

        let resp: ExplainResponse = try await PollyAPIClient.shared.post("v1/ai/explain", body: body)

        let result = ExplanationResult(
            sentence: resp.sentence,
            natural_translation: resp.natural_translation,
            core_explanation: resp.core_explanation,
            key_vocab: resp.key_vocab,
            grammar_point: resp.grammar_point,
            cultural_note: resp.cultural_note,
            pronunciation_tip: resp.pronunciation_tip,
            similar_expressions: resp.similar_expressions
        )
        cache[key] = result
        return result
    }
}

// MARK: - DTOs (对齐 polly-server/app/schemas.py 的 ExplainIn / ExplainOut)

private struct ExplainRequest: Encodable {
    let sentence: String
    let video_id: String?
    let segment_id: Int?
    let video_title: String?
    let video_author: String?
    let video_source: String?
    let cefr_level: String?
    let context_before: String?
    let context_after: String?
}

private struct ExplainResponse: Decodable {
    let sentence: String
    let natural_translation: String
    let core_explanation: String
    let key_vocab: [ExplanationResult.VocabItem]
    let grammar_point: String?
    let cultural_note: String?
    let pronunciation_tip: String?
    let similar_expressions: [String]?
    let model: String
    let cached: Bool
}
