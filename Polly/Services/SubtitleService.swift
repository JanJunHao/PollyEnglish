import Foundation

enum SubtitleService {
    /// 从 Bundle 加载指定视频的字幕。失败返回 nil。
    /// 文件命名约定：`demo-<video.id>.json`（与 video.id 完整匹配）。
    static func load(videoId: String) -> SubtitleDocument? {
        let candidates = ["demo-\(videoId)", videoId]
        for name in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: "json") {
                return load(from: url)
            }
        }
        return nil
    }

    static func load(from url: URL) -> SubtitleDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SubtitleDocument.self, from: data)
    }

    /// 远端字幕下载：用于 ImportYouTubeSheet 生成完成后拉 SubtitleJob 产物。
    /// 不抛错，失败返回 nil，调用方自己处理（通常给用户一个 "字幕加载失败" 提示）。
    static func loadAsync(from urlString: String) async -> SubtitleDocument? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(SubtitleDocument.self, from: data)
        } catch {
            print("[SubtitleService] remote load failed: \(error)")
            return nil
        }
    }
}

extension Array where Element == SubtitleSegment {
    /// 给定 currentTime，找到当前句的 index。线性搜索（句子数 < 1000 足够快）。
    /// 找不到（currentTime 在两句之间）时返回最近的下一句。
    func currentIndex(at time: Double) -> Int? {
        for (idx, seg) in enumerated() {
            if time >= seg.start && time <= seg.end {
                return idx
            }
            if time < seg.start {
                return Swift.max(0, idx - 1)  // 处于两句间，吸附到上一句
            }
        }
        return isEmpty ? nil : count - 1
    }
}
