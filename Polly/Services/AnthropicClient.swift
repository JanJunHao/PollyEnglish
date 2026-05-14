import Foundation

/// 通过代理网关调 LLM。
/// 当前网关（api.aaai.vip）使用 OpenAI 兼容 schema（chat completions）。
/// Key 和 baseURL 通过 Info.plist 注入（来自 Secrets.xcconfig → Generated.xcconfig）。
///
/// 类名暂保留 `AnthropicClient`，避免重命名连锁；后续可改名为 LLMClient。
final class AnthropicClient {
    static let shared = AnthropicClient()

    private let token: String
    private let baseURL: URL
    private let session: URLSession

    private init() {
        let bundle = Bundle.main
        self.token = (bundle.object(forInfoDictionaryKey: "AnthropicAuthToken") as? String) ?? ""
        let urlString = (bundle.object(forInfoDictionaryKey: "AnthropicBaseURL") as? String) ?? ""
        self.baseURL = URL(string: urlString) ?? URL(string: "https://api.aaai.vip/v1")!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    enum Model: String {
        case gpt4o          = "gpt-4o"
        case gpt4oMini      = "gpt-4o-mini"
        case claudeSonnet45 = "claude-sonnet-4-5"
        case claudeOpus47   = "claude-opus-4-7"
        case deepseekChat   = "deepseek-chat"
    }

    // OpenAI Chat Completions schema

    struct Message: Codable {
        let role: String        // "system" | "user" | "assistant"
        let content: String
    }

    struct Request: Codable {
        let model: String
        let messages: [Message]
        let max_tokens: Int
        let temperature: Double?
    }

    struct Response: Codable {
        let choices: [Choice]
        struct Choice: Codable {
            let message: Message
        }
    }

    enum APIError: LocalizedError {
        case invalidResponse(status: Int, body: String)
        case decodeFailed(Error)
        case emptyContent

        var errorDescription: String? {
            switch self {
            case .invalidResponse(let status, let body):
                let preview = body.count > 200 ? String(body.prefix(200)) + "..." : body
                return "HTTP \(status)\n\(preview)"
            case .decodeFailed(let e):
                return "解析失败：\(e.localizedDescription)"
            case .emptyContent:
                return "空响应"
            }
        }
    }

    /// 调用 chat completions，返回首条消息内容。
    func complete(model: Model = .gpt4o,
                  system: String,
                  user: String,
                  maxTokens: Int = 1024,
                  temperature: Double? = 0.7) async throws -> String {

        var req = URLRequest(url: chatCompletionsURL())
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = Request(
            model: model.rawValue,
            messages: [
                Message(role: "system", content: system),
                Message(role: "user", content: user)
            ],
            max_tokens: maxTokens,
            temperature: temperature
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(status: -1, body: "")
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw APIError.invalidResponse(status: http.statusCode, body: bodyStr)
        }

        do {
            let parsed = try JSONDecoder().decode(Response.self, from: data)
            guard let text = parsed.choices.first?.message.content, !text.isEmpty else {
                throw APIError.emptyContent
            }
            return text
        } catch let e as DecodingError {
            throw APIError.decodeFailed(e)
        }
    }

    /// 处理 baseURL 已含或未含 /v1 的两种情况，避免双 /v1/v1/chat/completions。
    private func chatCompletionsURL() -> URL {
        let path = baseURL.path
        if path.hasSuffix("/v1") || path.hasSuffix("/v1/") {
            return baseURL.appendingPathComponent("chat/completions")
        }
        return baseURL.appendingPathComponent("v1/chat/completions")
    }
}
