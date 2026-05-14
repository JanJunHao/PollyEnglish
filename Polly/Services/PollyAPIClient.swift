import Foundation

/// 与 polly-server (FastAPI) 通信的统一 HTTP 客户端。
/// baseURL 由 Info.plist["PollyServerURL"] 注入（来自 Secrets.xcconfig）。
/// 端点对齐 polly-server/app/api/。
final class PollyAPIClient {
    static let shared = PollyAPIClient()

    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "PollyServerURL") as? String) ?? ""
        self.baseURL = URL(string: raw) ?? URL(string: "http://127.0.0.1:8000")!
        self.apiKey = (Bundle.main.object(forInfoDictionaryKey: "PollyAPIKey") as? String) ?? ""

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            // 把 Python isoformat 的微秒 (6 位) 截断到毫秒 (3 位)，让 ISO8601DateFormatter 能吃
            let normalized = Self.normalizeISO8601(raw)
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFractional.date(from: normalized) { return d }
            let isoPlain = ISO8601DateFormatter()
            isoPlain.formatOptions = [.withInternetDateTime]
            if let d = isoPlain.date(from: normalized) { return d }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601: \(raw)")
        }
        self.encoder = JSONEncoder()
    }

    /// 把 Python isoformat 标准化为 iOS ISO8601DateFormatter 能吃的格式：
    /// - 6 位微秒 → 3 位毫秒
    /// - 没时区后缀（naive datetime）→ 补 Z（按 UTC 处理）
    private static func normalizeISO8601(_ s: String) -> String {
        guard let dot = s.firstIndex(of: ".") else {
            if s.hasSuffix("Z") || s.contains("+") { return s }
            return s + "Z"
        }
        let afterDot = s.index(after: dot)
        // Time-zone suffix starts at first Z/+ after the dot (date '-' before dot is not in this range).
        let suffixIdx = s[afterDot...].firstIndex(where: { $0 == "Z" || $0 == "+" || $0 == "-" })
        let fractional: Substring
        let suffix: String
        if let suffixIdx {
            fractional = s[afterDot..<suffixIdx]
            suffix = String(s[suffixIdx...])
        } else {
            fractional = s[afterDot...]
            suffix = "Z"
        }
        return String(s[..<dot]) + "." + fractional.prefix(3) + suffix
    }

    enum APIError: LocalizedError {
        case network(URLError)
        case http(status: Int, body: String)
        case decode(Error)
        case quotaExceeded(kind: String, tier: String, upgradeTo: String)

        var errorDescription: String? {
            switch self {
            case .network(let e): return "网络错误：\(e.localizedDescription)"
            case .http(let s, let b):
                let preview = b.count > 200 ? String(b.prefix(200)) + "..." : b
                return "HTTP \(s)\n\(preview)"
            case .decode(let e): return "解析失败：\(e.localizedDescription)"
            case .quotaExceeded(let kind, let tier, let upgrade):
                return "已用完今日 \(kind) 配额（\(tier) 档），升级到 \(upgrade) 解锁更多"
            }
        }
    }

    func get<Out: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> Out {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { comps.queryItems = query }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        attachAuth(&req)
        return try await send(req)
    }

    func post<In: Encodable, Out: Decodable>(_ path: String, body: In) async throws -> Out {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        attachAuth(&req)
        return try await send(req)
    }

    private func attachAuth(_ req: inout URLRequest) {
        guard !apiKey.isEmpty else { return }
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    }

    private func send<Out: Decodable>(_ req: URLRequest) async throws -> Out {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch let urlErr as URLError {
            throw APIError.network(urlErr)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(status: -1, body: "")
        }
        guard (200..<300).contains(http.statusCode) else {
            // 402 quota_exceeded：解析 detail，触发 paywall，再抛 typed 错误
            if http.statusCode == 402,
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = dict["detail"] as? [String: Any],
               detail["error"] as? String == "quota_exceeded" {
                let kind = detail["kind"] as? String ?? "?"
                let tier = detail["tier"] as? String ?? "free"
                let upgrade = detail["upgrade_to"] as? String ?? "plus"
                await PaywallManager.shared.trigger(kind: kind, tier: tier, upgradeTo: upgrade)
                throw APIError.quotaExceeded(kind: kind, tier: tier, upgradeTo: upgrade)
            }
            throw APIError.http(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        do {
            return try decoder.decode(Out.self, from: data)
        } catch {
            throw APIError.decode(error)
        }
    }
}
