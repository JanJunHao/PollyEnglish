import SwiftUI
import SwiftData

@main
struct PollyApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView {
                RootTabView()
            }
            .preferredColorScheme(.dark)
            .background(AppColors.bgPrimary)
        }
        .modelContainer(for: [VocabularyItem.self, SentenceFavorite.self, WatchEvent.self, LocalVideo.self])
    }
}
