import SwiftUI
import SwiftData

/// 我的 tab → 收藏句子。按视频分组展示。
struct FavoritesListView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SentenceFavorite.createdAt, order: .reverse) private var favorites: [SentenceFavorite]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bgPrimary.ignoresSafeArea()

                if favorites.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                            ForEach(grouped, id: \.title) { group in
                                section(title: group.title, items: group.items)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    }
                }
            }
            .navigationTitle("收藏句子")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(AppColors.brandPrimary)
                }
            }
            .toolbarBackground(AppColors.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Group by video

    private struct Group {
        let title: String
        let items: [SentenceFavorite]
    }

    private var grouped: [Group] {
        let byTitle = Dictionary(grouping: favorites) { $0.videoTitle ?? "未知视频" }
        return byTitle.map { Group(title: $0.key, items: $0.value) }
            .sorted { ($0.items.first?.createdAt ?? .distantPast) > ($1.items.first?.createdAt ?? .distantPast) }
    }

    // MARK: - Section

    private func section(title: String, items: [SentenceFavorite]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.brandPrimary)
                Text(title)
                    .font(AppFonts.body(13, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                    .lineLimit(1)
                Spacer()
                Text("\(items.count) 句")
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.textTertiary)
            }
            VStack(spacing: AppSpacing.sm) {
                ForEach(items) { item in
                    row(item)
                }
            }
        }
    }

    private func row(_ item: SentenceFavorite) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.text)
                .font(AppFonts.body(15, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
            if let zh = item.translation, !zh.isEmpty {
                Text(zh)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.subtitleChinese)
            }
            HStack {
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppFonts.mono(10))
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Button {
                    ctx.delete(item)
                    try? ctx.save()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "bookmark")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(AppColors.textTertiary)
            Text("还没有收藏的句子")
                .font(AppFonts.body(15, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            Text("在播放器字幕区点击 ⭐ 收藏喜欢的句子")
                .font(AppFonts.body(12))
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FavoritesListView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [VocabularyItem.self, SentenceFavorite.self, WatchEvent.self], inMemory: true)
}
