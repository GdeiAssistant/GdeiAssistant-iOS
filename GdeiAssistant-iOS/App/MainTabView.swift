import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var router: AppRouter

    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var messagesViewModel: MessagesViewModel
    @StateObject private var profileViewModel: ProfileViewModel

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        _homeViewModel = StateObject(wrappedValue: container.makeHomeViewModel())
        _messagesViewModel = StateObject(wrappedValue: container.makeMessagesViewModel())
        _profileViewModel = StateObject(wrappedValue: container.makeProfileViewModel())
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label("tab.home", systemImage: "house")
                }
                .tag(AppTab.home)

            MessagesView(viewModel: messagesViewModel)
                .tabItem {
                    Label("tab.info", systemImage: "bell.badge")
                }
                .tag(AppTab.messages)

            ProfileView(viewModel: profileViewModel)
                .tabItem {
                    Label("tab.profile", systemImage: "person.crop.circle")
                }
                .tag(AppTab.profile)
        }
        .onReceive(container.environment.$dataSourceMode.dropFirst().removeDuplicates()) { mode in
            homeViewModel.updateRepository(
                container.campusServicesAssembly.scheduleRepository(for: mode)
            )
            messagesViewModel.updateRepositories(
                newsRepository: container.campusServicesAssembly.newsRepository(for: mode),
                messagesRepository: container.profileAssembly.messagesRepository(for: mode)
            )
            profileViewModel.updateRepository(
                container.profileAssembly.profileRepository(for: mode)
            )
        }
        .tint(preferences.selectedAccent.primary)
        .toolbarBackground(DSColor.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(\.dsCampusAccent, preferences.selectedAccent)
    }
}

#if DEBUG
#Preview {
    let container = AppContainer.preview
    return MainTabView(container: container)
        .environmentObject(container)
        .environmentObject(container.userPreferences)
        .environmentObject(container.router)
}
#endif
