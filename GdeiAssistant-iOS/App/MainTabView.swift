import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView(viewModel: container.makeHomeViewModel())
                .tabItem {
                    Label("首页", systemImage: "house")
                }
                .tag(AppTab.home)

            MessagesView(viewModel: container.makeMessagesViewModel())
                .tabItem {
                    Label("资讯", systemImage: "bell.badge")
                }
                .tag(AppTab.messages)

            ProfileView(viewModel: container.makeProfileViewModel())
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(AppTab.profile)
        }
        .tint(DSColor.primary)
    }
}

#Preview {
    let container = AppContainer.preview
    return MainTabView()
        .environmentObject(container)
        .environmentObject(container.router)
}
