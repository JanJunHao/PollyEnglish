import SwiftUI

/// 首页「精选专辑」横滑模块。卡片设计与 FeaturedCourseRow 同源（160pt 宽）但更高更彩。
struct AlbumSection: View {
    let albums: [Album]
    let videoPool: [DemoVideo]
    let onSelect: (Album) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("精选专辑")
                    .font(AppFonts.body(17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(albums) { album in
                        AlbumCard(album: album, videoCount: videoCount(album))
                            .onTapGesture { onSelect(album) }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    private func videoCount(_ album: Album) -> Int {
        AlbumService.shared.videos(in: album, from: videoPool).count
    }
}

private struct AlbumCard: View {
    let album: Album
    let videoCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [album.themeColor.opacity(0.85), album.themeColor.opacity(0.35)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )

                // 角标
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                    Spacer()
                    Text("\(videoCount) 个视频")
                        .font(AppFonts.body(10, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding(AppSpacing.md)
            }
            .frame(width: 200, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(AppFonts.body(14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                Text(album.subtitle)
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, AppSpacing.sm)
            .frame(width: 200, alignment: .leading)
        }
    }
}
