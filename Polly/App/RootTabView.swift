import SwiftUI

struct RootTabView: View {
    enum Tab: Hashable { case home, profile }

    @State private var selection: Tab = .home
    @StateObject private var paywall = PaywallManager.shared

    var body: some View {
        TabView(selection: $selection) {
            HomeView(switchToProfile: { selection = .profile })
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(Tab.home)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(AppColors.brandPrimary)
        .sheet(isPresented: $paywall.isPresented) {
            PaywallSheet().environmentObject(paywall)
        }
    }
}

#Preview {
    RootTabView()
        .preferredColorScheme(.dark)
}
