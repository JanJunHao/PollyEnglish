import SwiftUI
import SwiftData

/// 生词本列表页。文档 04.7 占位实现：
/// 显示按时间倒序的生词，每条含原词、词形、释义、来源视频、时间戳。
struct VocabularyListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    @Query(sort: \VocabularyItem.createdAt, order: .reverse) private var items: [VocabularyItem]

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.sm) {
                            ForEach(items) { item in
                                VocabularyRow(item: item, onDelete: {
                                    ctx.delete(item)
                                })
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AppColors.bgElevated))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("生词本")
                    .font(AppFonts.display(20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("\(items.count) 个词")
                    .font(AppFonts.mono(11))
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 54)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text("还没有收藏的生词")
                .font(AppFonts.body(15, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            Text("观看视频时点击单词右上角 ☆ 收藏")
                .font(AppFonts.body(12))
                .foregroundColor(AppColors.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct VocabularyRow: View {
    let item: VocabularyItem
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Text(item.word)
                    .font(AppFonts.display(20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                if let p = item.phonetic {
                    Text(p)
                        .font(AppFonts.mono(11))
                        .foregroundColor(AppColors.textTertiary)
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            if !item.meanings.isEmpty {
                Text(item.meanings.joined(separator: " · "))
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.textSecondary)
            }

            if let ctx = item.contextSentence, !ctx.isEmpty {
                Text(ctx)
                    .font(.system(size: 11).italic())
                    .foregroundColor(AppColors.textTertiary)
                    .lineLimit(2)
            }

            HStack(spacing: AppSpacing.sm) {
                if let title = item.sourceVideoTitle {
                    Text(title)
                        .font(AppFonts.mono(10))
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                Text(item.createdAt.formatted(.relative(presentation: .named)))
                    .font(AppFonts.mono(10))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }
}
