import Foundation

/// 外刊内容服务：拉取 polly-server 的 /v1/articles/latest。
/// 策略与 ContentService 一致：唯一来源是服务端，失败时保留上一次快照。
@MainActor
final class ArticleService: ObservableObject {
    static let shared = ArticleService()

    @Published private(set) var articles: [Article] = []
    @Published private(set) var lastError: String?

    private init() {}

    func refresh() async {
        do {
            let resp: ArticlesLatestResponse = try await PollyAPIClient.shared.get("v1/articles/latest")
            self.articles = resp.articles.map(Article.init(dto:))
            self.lastError = nil
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            print("[ArticleService] refresh failed: \(msg)")
            self.lastError = msg
        }
    }
}

// MARK: - DTOs（与 polly-server /v1/articles/latest 对齐）

private struct ArticlesLatestResponse: Decodable {
    let server_time: Date
    let version: Int
    let articles: [ArticleDTO]
}

struct ArticleSegmentDTO: Decodable {
    let id: Int
    let text: String
    let translation: String
    let paragraph: Int
}

struct ArticleDTO: Decodable {
    let id: String
    let title: String
    let author: String
    let source: String
    let cefr_level: String
    let topics: [String]
    let word_count: Int
    let reading_time_seconds: Int
    let updated_at: Date
    let body: String
    let paragraphs: [ArticleSegmentDTO]
    let image_urls: [String]
    let thumbnail_url: String
    let attribution: String?
}

extension Article {
    init(dto: ArticleDTO) {
        self.id = dto.id
        self.title = dto.title
        self.source = dto.source
        self.author = dto.author
        self.cefrLevel = dto.cefr_level
        self.topics = dto.topics
        self.wordCount = dto.word_count
        self.readingMinutes = max(1, Int((Double(dto.reading_time_seconds) / 60).rounded()))
        self.updatedAt = dto.updated_at
        self.body = dto.body
        self.excerpt = Article.makeExcerpt(from: dto.body)
        self.paragraphs = dto.paragraphs.map {
            ArticleSegment(id: $0.id, text: $0.text,
                           translation: $0.translation, paragraph: $0.paragraph)
        }
        self.imageURLs = dto.image_urls
        self.thumbnailURL = dto.thumbnail_url
        self.attribution = dto.attribution
    }

    /// 摘要：取正文首段，超长截断到 ~150 字。
    static func makeExcerpt(from body: String) -> String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstPara = trimmed.split(separator: "\n").first.map(String.init) ?? trimmed
        guard firstPara.count > 150 else { return firstPara }
        let cut = firstPara.index(firstPara.startIndex, offsetBy: 150)
        return String(firstPara[..<cut]).trimmingCharacters(in: .whitespaces) + "…"
    }
}
