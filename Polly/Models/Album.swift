import SwiftUI

/// 专辑：把 5–10 个视频聚合成一个主题（如「TED 演讲合集」「太空探索系列」）。
/// 文档 05.3：内容组织的二级单位，介于「单个视频」和「分类模块」之间。
struct Album: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String       // 一行副标题（适合卡片展示）
    let description: String    // 详情页长描述
    let videoIds: [String]     // contents.id 引用
    let themeColorHex: UInt32  // 卡片主题色 / detail header 渐变
    let coverImageName: String? // 可选 bundle 封面；nil 走渐变占位

    var themeColor: Color { Color(hex: themeColorHex) }
}
