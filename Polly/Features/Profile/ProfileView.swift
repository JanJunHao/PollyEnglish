import SwiftUI
import SwiftData

struct ProfileView: View {
    @StateObject private var userStore = UserStore.shared
    @Environment(\.modelContext) private var modelContext

    @Query private var vocabulary: [VocabularyItem]
    @Query private var favorites: [SentenceFavorite]

    enum ActiveSheet: String, Identifiable {
        case login, vocabulary, favorites, subtitleSettings, feedback, aiDialog, shadowingHistory, about, importYouTube, importLocal
        var id: String { rawValue }
    }
    @State private var activeSheet: ActiveSheet?
    @State private var showSignOutConfirm = false

    @StateObject private var sharedSubtitlePrefs = SubtitlePreferences()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.xl) {
                        userCard

                        statsRow

                        menuList

                        if userStore.isSignedIn {
                            signOutButton
                        }

                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.top, AppSpacing.lg)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppColors.bgPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .login:
                LoginSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            case .vocabulary:
                VocabularyListView()
                    .presentationDetents([.large])
            case .favorites:
                FavoritesListView()
                    .presentationDetents([.large])
            case .subtitleSettings:
                SubtitleSettingsSheet(prefs: sharedSubtitlePrefs) { activeSheet = nil }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            case .feedback:
                FeedbackSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .aiDialog:
                ComingSoonCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "AI 对话练习",
                    desc: "场景化口语练习（机场 / 餐厅 / 面试），多轮 AI 对话 + 实时反馈。即将上线 ✦"
                ) { activeSheet = nil }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            case .shadowingHistory:
                ComingSoonCard(
                    icon: "waveform",
                    title: "跟读历史",
                    desc: "在播放器里跟读后会自动保存录音和评分曲线。即将上线 ✦"
                ) { activeSheet = nil }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            case .about:
                AboutSheet { activeSheet = nil }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            case .importYouTube:
                ImportYouTubeSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            case .importLocal:
                ImportLocalVideoSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .confirmationDialog("确定要退出登录吗？", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("退出登录", role: .destructive) {
                userStore.signOut()
            }
            Button("取消", role: .cancel) {}
        }
    }

    // MARK: - User Card

    private var userCard: some View {
        VStack(spacing: AppSpacing.md) {
            if let user = userStore.user {
                avatar(initial: user.avatarInitial)

                VStack(spacing: 4) {
                    Text(user.name)
                        .font(AppFonts.display(22, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("通过 \(user.method.displayName) 登录")
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.textTertiary)
                }
            } else {
                avatar(initial: "?")
                    .opacity(0.6)

                VStack(spacing: AppSpacing.sm) {
                    Text("未登录")
                        .font(AppFonts.display(20, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("登录后同步学习进度、生词本与收藏")
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }

                Button {
                    activeSheet = .login
                } label: {
                    Text("立即登录")
                        .font(AppFonts.body(15, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(AppColors.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    private func avatar(initial: String) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 84, height: 84)

            Text(initial)
                .font(AppFonts.display(34, weight: .bold))
                .foregroundColor(.black)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AppSpacing.md) {
            statCell(value: "\(vocabulary.count)", label: "生词", icon: "character.book.closed.fill") {
                activeSheet = .vocabulary
            }
            statCell(value: "\(favorites.count)", label: "收藏句子", icon: "bookmark.fill") {
                activeSheet = .favorites
            }
            statCell(value: "0", label: "学习天数", icon: "flame.fill") {
                // 学习记录占位
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func statCell(value: String, label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.brandPrimary)

                Text(value)
                    .font(AppFonts.display(20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(label)
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Menu

    private var menuList: some View {
        VStack(spacing: 0) {
            menuRow(icon: "character.book.closed.fill", title: "生词本", subtitle: "\(vocabulary.count) 个单词") {
                activeSheet = .vocabulary
            }
            divider
            menuRow(icon: "bookmark.fill", title: "收藏句子", subtitle: "\(favorites.count) 句") {
                activeSheet = .favorites
            }
            divider
            menuRow(icon: "bubble.left.and.bubble.right.fill", title: "AI 对话练习", subtitle: "场景化口语 · 即将上线") {
                activeSheet = .aiDialog
            }
            divider
            menuRow(icon: "waveform", title: "跟读历史", subtitle: "即将上线") {
                activeSheet = .shadowingHistory
            }
            divider
            menuRow(icon: "link.badge.plus", title: "从 YouTube 导入", subtitle: "粘 URL → 自动生成字幕") {
                activeSheet = .importYouTube
            }
            divider
            menuRow(icon: "folder.badge.plus", title: "导入本地视频", subtitle: "选 mp4 / mov · WhisperKit 离线转录") {
                activeSheet = .importLocal
            }
            divider
            menuRow(icon: "gearshape.fill", title: "字幕与播放设置", subtitle: "字体、字号、显示") {
                activeSheet = .subtitleSettings
            }
            divider
            menuRow(icon: "questionmark.circle.fill", title: "帮助与反馈", subtitle: nil) {
                activeSheet = .feedback
            }
            divider
            menuRow(icon: "info.circle.fill", title: "关于 Polly", subtitle: "v0.1.0") {
                activeSheet = .about
            }
        }
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        .padding(.horizontal, AppSpacing.lg)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 56)
    }

    private func menuRow(icon: String, title: String, subtitle: String?, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.brandPrimary)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.body(15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppFonts.body(11))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
            .opacity(disabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            Text("退出登录")
                .font(AppFonts.body(15, weight: .medium))
                .foregroundColor(.red.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.lg)
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [VocabularyItem.self, SentenceFavorite.self, WatchEvent.self], inMemory: true)
}
