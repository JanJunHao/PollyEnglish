import SwiftUI

struct RootTabView: View {
    enum Tab: Hashable { case discover, files, profile }

    @Environment(\.theme) private var theme
    // 默认底部 tab；开发期可用 --bottomtab-files / --bottomtab-profile 直接定位（截图用）。
    @State private var selection: Tab = {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--bottomtab-files")   { return .files }
        if args.contains("--bottomtab-profile") { return .profile }
        return .discover
    }()
    @StateObject private var paywall = PaywallManager.shared

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Label("探索", systemImage: "safari.fill")
                }
                .tag(Tab.discover)

            FilesView()
                .tabItem {
                    Label("文件", systemImage: "folder.fill")
                }
                .tag(Tab.files)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(theme.brandText)
        .sheet(isPresented: $paywall.isPresented) {
            PaywallSheet().environmentObject(paywall)
        }
    }
}

#Preview {
    RootTabView()
}
