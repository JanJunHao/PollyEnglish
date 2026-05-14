import SwiftUI

struct FeaturedCourseRow: View {
    let videos: [DemoVideo]
    let onSelect: (DemoVideo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("精选课程")
                .font(AppFonts.body(17, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(videos) { video in
                        CourseCard(video: video) { onSelect(video) }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }
}

private struct CourseCard: View {
    let video: DemoVideo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 90)
                        .clipped()

                    // 左上角分类色圆点
                    Circle()
                        .fill(video.categoryColor)
                        .frame(width: 8, height: 8)
                        .padding(AppSpacing.sm)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(video.title)
                        .font(AppFonts.body(14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(video.durationDisplay) · \(video.cefrLevel)")
                        .font(AppFonts.mono(11))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 160)
            .background(AppColors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FeaturedCourseRow(videos: DemoVideo.all, onSelect: { _ in })
        .preferredColorScheme(.dark)
        .background(AppColors.bgPrimary)
}
