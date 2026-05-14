import Foundation

/// 字幕文件结构（文档 04.4 subtitles.json）。
struct SubtitleDocument: Codable {
    let videoId: String
    let language: String?
    let segments: [SubtitleSegment]

    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case language
        case segments
    }
}

/// 一句字幕。
struct SubtitleSegment: Codable, Identifiable, Hashable {
    let id: Int
    let start: Double
    let end: Double
    let text: String
    var translation: String?
    let words: [SubtitleWord]

    init(id: Int, start: Double, end: Double, text: String, translation: String? = nil, words: [SubtitleWord] = []) {
        self.id = id
        self.start = start
        self.end = end
        self.text = text
        self.translation = translation
        self.words = words
    }

    enum CodingKeys: String, CodingKey {
        case id, start, end, text, translation, words
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(Int.self, forKey: .id)
        self.start = try c.decode(Double.self, forKey: .start)
        self.end = try c.decode(Double.self, forKey: .end)
        self.text = try c.decode(String.self, forKey: .text)
        self.translation = try c.decodeIfPresent(String.self, forKey: .translation)
        self.words = try c.decodeIfPresent([SubtitleWord].self, forKey: .words) ?? []
    }
}

/// 一句中的一个单词，含字级时间戳（文档 03.5）。
struct SubtitleWord: Codable, Hashable {
    let w: String
    let s: Double
    let e: Double
}

extension SubtitleSegment {
    var duration: Double { end - start }
}
