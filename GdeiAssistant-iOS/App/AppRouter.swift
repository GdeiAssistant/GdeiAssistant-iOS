import Foundation
import Combine

enum AppTab: Hashable {
    case home
    case messages
    case profile
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home

    func resetAfterLogout() {
        selectedTab = .home
    }
}

@MainActor
final class AppContainer: ObservableObject {
    let router: AppRouter
    let userPreferences: UserPreferences
    let environment: AppEnvironment
    let sessionState: SessionState
    let authManager: AuthManager

    // MARK: - Assemblies

    let coreAssembly: CoreAssembly
    let campusServicesAssembly: CampusServicesAssembly
    let communityAssembly: CommunityAssembly
    let profileAssembly: ProfileAssembly

    // MARK: - Repository accessors (forwarded from assemblies)

    var authRepository: any AuthRepository { coreAssembly.authRepository }
    var homeRepository: any HomeRepository { coreAssembly.homeRepository }

    var scheduleRepository: any ScheduleRepository { campusServicesAssembly.scheduleRepository }
    var gradeRepository: any GradeRepository { campusServicesAssembly.gradeRepository }
    var cardRepository: any CardRepository { campusServicesAssembly.cardRepository }
    var libraryRepository: any LibraryRepository { campusServicesAssembly.libraryRepository }
    var cetRepository: any CETRepository { campusServicesAssembly.cetRepository }
    var evaluateRepository: any EvaluateRepository { campusServicesAssembly.evaluateRepository }
    var spareRepository: any SpareRepository { campusServicesAssembly.spareRepository }
    var graduateExamRepository: any GraduateExamRepository { campusServicesAssembly.graduateExamRepository }
    var newsRepository: any NewsRepository { campusServicesAssembly.newsRepository }
    var dataCenterRepository: any DataCenterRepository { campusServicesAssembly.dataCenterRepository }

    var communityRepository: any CommunityRepository { communityAssembly.communityRepository }
    var topicRepository: any TopicRepository { communityAssembly.topicRepository }
    var expressRepository: any ExpressRepository { communityAssembly.expressRepository }
    var deliveryRepository: any DeliveryRepository { communityAssembly.deliveryRepository }
    var photographRepository: any PhotographRepository { communityAssembly.photographRepository }
    var marketplaceRepository: any MarketplaceRepository { communityAssembly.marketplaceRepository }
    var lostFoundRepository: any LostFoundRepository { communityAssembly.lostFoundRepository }
    var secretRepository: any SecretRepository { communityAssembly.secretRepository }
    var datingRepository: any DatingRepository { communityAssembly.datingRepository }

    var profileRepository: any ProfileRepository { profileAssembly.profileRepository }
    var accountCenterRepository: any AccountCenterRepository { profileAssembly.accountCenterRepository }
    var messagesRepository: any MessagesRepository { profileAssembly.messagesRepository }

    private var hasBootstrapped = false
    private let shouldSkipBootstrap: Bool

    init(
        userPreferences: UserPreferences,
        tokenStorage: TokenStorage,
        shouldSkipBootstrap: Bool = false
    ) {
        self.router = AppRouter()
        self.userPreferences = userPreferences
        self.environment = AppEnvironment(
            networkEnvironment: userPreferences.currentNetworkEnvironment,
            dataSourceMode: userPreferences.currentDataSourceMode
        )
        self.sessionState = SessionState()
        self.shouldSkipBootstrap = shouldSkipBootstrap

        let authManager = AuthManager(tokenStorage: tokenStorage, sessionState: sessionState)
        self.authManager = authManager

        let apiClient = APIClient(
            environment: environment,
            tokenProvider: { [weak authManager] in
                authManager?.currentToken()
            },
            onUnauthorized: { [weak authManager] in
                authManager?.handleUnauthorized()
            }
        )

        // Construct assemblies
        self.coreAssembly = CoreAssembly(apiClient: apiClient, environment: environment)
        self.campusServicesAssembly = CampusServicesAssembly(apiClient: apiClient, environment: environment)
        self.communityAssembly = CommunityAssembly(apiClient: apiClient, environment: environment)
        self.profileAssembly = ProfileAssembly(apiClient: apiClient, environment: environment)

        authManager.configure(
            repository: coreAssembly.authRepository,
            dataSourceModeProvider: { [weak environment] in
                environment?.dataSourceMode ?? .remote
            }
        )
    }

    convenience init() {
        self.init(userPreferences: UserPreferences(), tokenStorage: KeychainTokenStorage())
    }

    @MainActor
    static var preview: AppContainer {
        let suiteName = "gdeiassistant.preview.defaults"
        let previewDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        previewDefaults.removePersistentDomain(forName: suiteName)
        let preferences = UserPreferences(defaults: previewDefaults)
        preferences.setUseMockData(true)
        let container = AppContainer(userPreferences: preferences, tokenStorage: InMemoryTokenStorage())
        container.environment.updateDataSourceMode(.mock)
        container.sessionState.markLoggedIn(user: MockFactory.makeUserProfile())
        container.sessionState.isRestoringSession = false
        return container
    }

    @MainActor
    static var testing: AppContainer {
        let suiteName = "gdeiassistant.tests.defaults"
        let testDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        testDefaults.removePersistentDomain(forName: suiteName)
        let preferences = UserPreferences(defaults: testDefaults)
        let container = AppContainer(
            userPreferences: preferences,
            tokenStorage: InMemoryTokenStorage(),
            shouldSkipBootstrap: true
        )
        container.sessionState.markLoggedOut()
        return container
    }

    func bootstrapIfNeeded(force: Bool = false) async {
        guard force || !hasBootstrapped else { return }
        hasBootstrapped = true
        guard !shouldSkipBootstrap else {
            sessionState.markLoggedOut()
            return
        }
        await authManager.restoreSession()
    }

    // MARK: - ViewModel Factories

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authManager: authManager)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(repository: homeRepository)
    }

    func makeCommunityViewModel() -> CommunityFeedViewModel {
        CommunityFeedViewModel(repository: communityRepository)
    }

    func makeTopicViewModel() -> TopicViewModel {
        TopicViewModel(repository: topicRepository)
    }

    func makePublishTopicViewModel() -> PublishTopicViewModel {
        PublishTopicViewModel(repository: topicRepository)
    }

    func makeExpressViewModel() -> ExpressViewModel {
        ExpressViewModel(repository: expressRepository)
    }

    func makePublishExpressViewModel() -> PublishExpressViewModel {
        PublishExpressViewModel(repository: expressRepository)
    }

    func makeDeliveryViewModel() -> DeliveryViewModel {
        DeliveryViewModel(repository: deliveryRepository)
    }

    func makePublishDeliveryViewModel() -> PublishDeliveryViewModel {
        PublishDeliveryViewModel(repository: deliveryRepository)
    }

    func makePhotographViewModel() -> PhotographViewModel {
        PhotographViewModel(repository: photographRepository)
    }

    func makePublishPhotographViewModel() -> PublishPhotographViewModel {
        PublishPhotographViewModel(repository: photographRepository)
    }

    func makePostDetailViewModel(postID: String) -> PostDetailViewModel {
        PostDetailViewModel(postID: postID, repository: communityRepository)
    }

    func makeTopicFeedViewModel(topicID: String) -> TopicFeedViewModel {
        TopicFeedViewModel(topicID: topicID, repository: communityRepository)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(repository: profileRepository, sessionState: sessionState)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(environment: environment, preferences: userPreferences)
    }

    func makePrivacySettingsViewModel() -> PrivacySettingsViewModel {
        PrivacySettingsViewModel(repository: accountCenterRepository)
    }

    func makeLoginRecordViewModel() -> LoginRecordViewModel {
        LoginRecordViewModel(repository: accountCenterRepository)
    }

    func makeBindPhoneViewModel() -> BindPhoneViewModel {
        BindPhoneViewModel(repository: accountCenterRepository)
    }

    func makeBindEmailViewModel() -> BindEmailViewModel {
        BindEmailViewModel(repository: accountCenterRepository)
    }

    func makeFeedbackViewModel() -> FeedbackViewModel {
        FeedbackViewModel(repository: accountCenterRepository)
    }

    func makeDownloadDataViewModel() -> DownloadDataViewModel {
        DownloadDataViewModel(repository: accountCenterRepository)
    }

    func makeAvatarEditViewModel() -> AvatarEditViewModel {
        AvatarEditViewModel(repository: accountCenterRepository, sessionState: sessionState)
    }

    func makeDeleteAccountViewModel() -> DeleteAccountViewModel {
        DeleteAccountViewModel(repository: accountCenterRepository)
    }

    func makeScheduleViewModel() -> ScheduleViewModel {
        ScheduleViewModel(repository: scheduleRepository)
    }

    func makeGradeViewModel() -> GradeViewModel {
        GradeViewModel(repository: gradeRepository)
    }

    func makeCardViewModel() -> CardViewModel {
        CardViewModel(repository: cardRepository)
    }

    func makeLibraryViewModel() -> LibraryViewModel {
        LibraryViewModel(repository: libraryRepository)
    }

    func makeCETViewModel() -> CETViewModel {
        CETViewModel(repository: cetRepository)
    }

    func makeEvaluateViewModel() -> EvaluateViewModel {
        EvaluateViewModel(repository: evaluateRepository)
    }

    func makeSpareViewModel() -> SpareViewModel {
        SpareViewModel(repository: spareRepository)
    }

    func makeGraduateExamViewModel() -> GraduateExamViewModel {
        GraduateExamViewModel(repository: graduateExamRepository)
    }

    func makeNewsViewModel() -> NewsViewModel {
        NewsViewModel(repository: newsRepository)
    }

    func makeMarketplaceViewModel() -> MarketplaceViewModel {
        MarketplaceViewModel(repository: marketplaceRepository)
    }

    func makePublishMarketplaceViewModel() -> PublishMarketplaceViewModel {
        PublishMarketplaceViewModel()
    }

    func makeLostFoundViewModel() -> LostFoundViewModel {
        LostFoundViewModel(repository: lostFoundRepository)
    }

    func makePublishLostFoundViewModel() -> PublishLostFoundViewModel {
        PublishLostFoundViewModel()
    }

    func makeSecretViewModel() -> SecretViewModel {
        SecretViewModel(repository: secretRepository)
    }

    func makeDatingViewModel() -> DatingHallViewModel {
        DatingHallViewModel(repository: datingRepository)
    }

    func makePublishSecretViewModel() -> PublishSecretViewModel {
        PublishSecretViewModel()
    }

    func makePublishDatingViewModel() -> PublishDatingViewModel {
        PublishDatingViewModel(profileRepository: profileRepository)
    }

    func makeDatingCenterViewModel(initialTab: DatingCenterTab = .received) -> DatingCenterViewModel {
        let viewModel = DatingCenterViewModel(repository: datingRepository)
        viewModel.selectedTab = initialTab
        return viewModel
    }

    func makeMessagesViewModel() -> MessagesViewModel {
        MessagesViewModel(
            newsRepository: newsRepository,
            messagesRepository: messagesRepository
        )
    }

    func makeSystemNoticeListViewModel() -> SystemNoticeListViewModel {
        SystemNoticeListViewModel(repository: messagesRepository)
    }

    func makeInteractionMessageListViewModel() -> InteractionMessageListViewModel {
        InteractionMessageListViewModel(repository: messagesRepository)
    }
}
