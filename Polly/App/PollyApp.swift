import SwiftUI
import SwiftData

@main
struct PollyApp: App {
    var body: some Scene {
        WindowGroup {
            ThemeProvider {
                SplashView {
                    RootTabView()
                }
            }
        }
        .modelContainer(for: [VocabularyItem.self, SentenceFavorite.self, WatchEvent.self, LocalVideo.self])
    }
}
