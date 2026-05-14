import Foundation

/// 专辑服务：当前从 bundle 内 albums.json 加载，Phase B 后切到 server。
/// 设计与 ContentService 同形：bundle fallback 永远在，server 接通后只是替换 published 数据。
@MainActor
final class AlbumService: ObservableObject {
    static let shared = AlbumService()

    @Published private(set) var albums: [Album]

    private init() {
        self.albums = Self.loadBundle() ?? []
    }

    /// 把专辑里的 videoIds 解出来，过滤掉当前内容池没有的视频。
    /// 视频顺序按 albums.json 内 video_ids 顺序保留。
    func videos(in album: Album, from pool: [DemoVideo]) -> [DemoVideo] {
        let byId = Dictionary(uniqueKeysWithValues: pool.map { ($0.id, $0) })
        return album.videoIds.compactMap { byId[$0] }
    }

    private static func loadBundle() -> [Album]? {
        guard let url = Bundle.main.url(forResource: "albums", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        do {
            let decoded = try JSONDecoder().decode(BundleFile.self, from: data)
            return decoded.albums.map {
                Album(
                    id: $0.id,
                    title: $0.title,
                    subtitle: $0.subtitle,
                    description: $0.description,
                    videoIds: $0.video_ids,
                    themeColorHex: UInt32($0.theme_color_hex),
                    coverImageName: $0.cover_image_name
                )
            }
        } catch {
            print("[AlbumService] decode failed: \(error)")
            return nil
        }
    }

    private struct BundleFile: Decodable {
        let version: Int
        let albums: [Item]
    }

    private struct Item: Decodable {
        let id: String
        let title: String
        let subtitle: String
        let description: String
        let video_ids: [String]
        let theme_color_hex: Int
        let cover_image_name: String?
    }
}
