import SwiftUI

/// 一个简单的 Flow / Wrap Layout：子 view 自然从左到右排列，超出宽度自动换行。
/// 用于把字幕的每个单词独立成 Button，同时保持自然换行（不能用 Text 拼接，因为 Text 不支持嵌套手势）。
struct FlowLayout: Layout {
    var hSpacing: CGFloat = 4
    var vSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var isFirstInRow = true

        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            let prospective = currentRowWidth + (isFirstInRow ? 0 : hSpacing) + size.width

            if prospective > maxWidth && !isFirstInRow {
                totalHeight += currentRowHeight + vSpacing
                currentRowWidth = size.width
                currentRowHeight = size.height
                isFirstInRow = false
            } else {
                currentRowWidth = prospective
                currentRowHeight = Swift.max(currentRowHeight, size.height)
                isFirstInRow = false
            }
        }
        totalHeight += currentRowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : currentRowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var currentRowHeight: CGFloat = 0
        var isFirstInRow = true

        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            let prospective = x + (isFirstInRow ? 0 : hSpacing) + size.width

            if prospective > bounds.maxX && !isFirstInRow {
                x = bounds.minX
                y += currentRowHeight + vSpacing
                currentRowHeight = 0
                isFirstInRow = true
            }

            if !isFirstInRow {
                x += hSpacing
            }
            sv.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width
            currentRowHeight = Swift.max(currentRowHeight, size.height)
            isFirstInRow = false
        }
    }
}
