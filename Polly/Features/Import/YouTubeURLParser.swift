import Foundation

/// 从各种 YouTube URL 格式抽 videoId。
/// 支持：
/// - https://www.youtube.com/watch?v=ID
/// - https://youtu.be/ID
/// - https://youtube.com/shorts/ID
/// - https://m.youtube.com/watch?v=ID
/// - 直接粘 11 位 videoId
enum YouTubeURLParser {
    static func videoId(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 直接是 11 位 videoId（YouTube 标准长度）
        if Self.isLikelyVideoId(trimmed) { return trimmed }

        guard let url = URL(string: trimmed) ?? URL(string: "https://" + trimmed) else { return nil }
        guard let host = url.host?.lowercased() else { return nil }

        // youtu.be/<id>
        if host.contains("youtu.be") {
            let id = String(url.path.dropFirst()).split(separator: "/").first.map(String.init) ?? ""
            return isLikelyVideoId(id) ? id : nil
        }

        guard host.contains("youtube.com") else { return nil }

        // /shorts/<id> or /embed/<id>
        let segments = url.pathComponents.filter { $0 != "/" }
        if let prefixIdx = segments.firstIndex(where: { ["shorts", "embed", "live"].contains($0) }),
           prefixIdx + 1 < segments.count {
            let id = segments[prefixIdx + 1]
            return isLikelyVideoId(id) ? id : nil
        }

        // /watch?v=<id>
        if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let v = comps.queryItems?.first(where: { $0.name == "v" })?.value,
           isLikelyVideoId(v) {
            return v
        }

        return nil
    }

    static func isLikelyVideoId(_ s: String) -> Bool {
        s.count == 11 && s.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }
}
