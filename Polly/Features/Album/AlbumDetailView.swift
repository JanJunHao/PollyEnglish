import SwiftUI

/// 专辑详情页：封面 + 描述 + 视频清单。从首页 AlbumSection 进入。
struct AlbumDetailView: View {
    let album: Album
    let videos: [DemoVideo]
    var onSelectVideo: (DemoVideo) -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                    descriptionBlock
                    videoList
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.bottom, AppSpacing.xxl)
            }

            VStack {
                topBar
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AppColors.bgElevated.opacity(0.7)))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [album.themeColor.opacity(0.9), album.themeColor.opacity(0.2), AppColors.bgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.black.opacity(0.7))
                Text(album.title)
                    .font(AppFonts.display(28, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(album.subtitle)
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(AppSpacing.lg)
        }
        .frame(height: 220)
    }

    private var descriptionBlock: some View {
        Text(album.description)
            .font(AppFonts.body(14))
            .foregroundColor(AppColors.textSecondary)
            .lineSpacing(4)
            .padding(.horizontal, AppSpacing.lg)
    }

    private var videoList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("收录视频 · \(videos.count)")
                .font(AppFonts.body(13, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .padding(.horizontal, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(videos.enumerated()), id: \.element.id) { idx, video in
                    Button { onSelectVideo(video) } label: {
                        videoRow(index: idx + 1, video: video)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private func videoRow(index: Int, video: DemoVideo) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text(String(format: "%02d", index))
                .font(AppFonts.mono(13, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 28, alignment: .leading)

            ThumbnailImage(name: video.thumbnailName, url: video.thumbnailURL)
                .aspectRatio(16.0/9.0, contentMode: .fill)
                .frame(width: 84, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(video.durationDisplay) · \(video.cefrLevel)")
                    .font(AppFonts.body(10))
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(album.themeColor)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }
}
