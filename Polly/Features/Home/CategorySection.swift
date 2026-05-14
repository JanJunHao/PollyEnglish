import SwiftUI

/// 首页的分类模块行：标签 + 横滑视频卡 + 空状态。
struct CategorySection: View {
    let category: VideoCategory
    let videos: [DemoVideo]
    let onSelect: (DemoVideo) -> Void
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            if videos.isEmpty {
                emptyState
                    .padding(.horizontal, AppSpacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(videos) { video in
                            CategoryCourseCard(video: video) { onSelect(video) }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            // 模块色 icon 胶囊
            HStack(spacing: 5) {
                Image(systemName: category.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(category.displayName)
                    .font(AppFonts.body(13, weight: .semibold))
            }
            .foregroundColor(category.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(category.accentColor.opacity(0.15))
            )

            Spacer()

            if !videos.isEmpty, let onSeeAll {
                Button(action: onSeeAll) {
                    HStack(spacing: 2) {
                        Text("查看全部")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var emptyState: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: category.icon)
                .font(.system(size: 18))
                .foregroundColor(category.accentColor.opacity(0.6))
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(category.accentColor.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("内容准备中")
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                Text("即将自动归类到该模块")
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }
}

private struct CategoryCourseCard: View {
    let video: DemoVideo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 100)
                        .clipped()
                    Circle()
                        .fill(video.categoryColor)
                        .frame(width: 8, height: 8)
                        .padding(AppSpacing.sm)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(AppFonts.body(13, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(video.durationDisplay) · \(video.cefrLevel)")
                        .font(AppFonts.mono(10))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 180)
            .background(AppColors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        }
        .buttonStyle(.plain)
    }
}
