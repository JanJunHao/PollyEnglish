import SwiftUI

/// 点首页分类「查看全部」弹出的完整列表页（modal sheet）。
/// 2 列网格 + 视频卡片，点卡进 PlayerView。
struct CategoryListView: View {
    let category: VideoCategory
    let videos: [DemoVideo]
    let onClose: () -> Void

    @State private var presentedVideo: DemoVideo?

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.md),
        GridItem(.flexible(), spacing: AppSpacing.md),
    ]

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                        ForEach(videos) { video in
                            Button {
                                presentedVideo = video
                            } label: {
                                videoCard(video)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $presentedVideo) { video in
            PlayerView(video: video)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(category.displayName)
                    .font(AppFonts.body(17, weight: .semibold))
            }
            .foregroundColor(category.accentColor)

            Spacer()

            Text("\(videos.count) 条")
                .font(AppFonts.mono(12))
                .foregroundColor(AppColors.textTertiary)
                .padding(.trailing, AppSpacing.lg)
        }
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.bgPrimary)
    }

    // MARK: - Card

    private func videoCard(_ video: DemoVideo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .clipped()

                Circle()
                    .fill(video.categoryColor)
                    .frame(width: 8, height: 8)
                    .padding(AppSpacing.sm)

                // 时长徽章右下
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(video.durationDisplay)
                            .font(AppFonts.mono(10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.6))
                            )
                            .padding(6)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(video.author) · \(video.cefrLevel)")
                    .font(AppFonts.mono(10))
                    .foregroundColor(AppColors.textTertiary)
                    .lineLimit(1)
            }
            .padding(AppSpacing.sm)
        }
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }
}
