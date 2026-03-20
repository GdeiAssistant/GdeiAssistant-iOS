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

    let authRepository: any AuthRepository
    let homeRepository: any HomeRepository
    let communityRepository: any CommunityRepository
    let topicRepository: any TopicRepository
    let expressRepository: any ExpressRepository
    let deliveryRepository: any DeliveryRepository
    let photographRepository: any PhotographRepository
    let profileRepository: any ProfileRepository
    let accountCenterRepository: any AccountCenterRepository
    let scheduleRepository: any ScheduleRepository
    let gradeRepository: any GradeRepository
    let cardRepository: any CardRepository
    let libraryRepository: any LibraryRepository
    let cetRepository: any CETRepository
    let evaluateRepository: any EvaluateRepository
    let spareRepository: any SpareRepository
    let graduateExamRepository: any GraduateExamRepository
    let newsRepository: any NewsRepository
    let dataCenterRepository: any DataCenterRepository
    let marketplaceRepository: any MarketplaceRepository
    let lostFoundRepository: any LostFoundRepository
    let secretRepository: any SecretRepository
    let datingRepository: any DatingRepository
    let messagesRepository: any MessagesRepository

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

        let remoteAuthRepository = RemoteAuthRepository(apiClient: apiClient)
        let mockAuthRepository = MockAuthRepository()
        self.authRepository = SwitchingAuthRepository(
            environment: environment,
            remoteRepository: remoteAuthRepository,
            mockRepository: mockAuthRepository
        )

        let remoteHomeRepository = RemoteHomeRepository(apiClient: apiClient)
        let mockHomeRepository = MockHomeRepository()
        self.homeRepository = SwitchingHomeRepository(
            environment: environment,
            remoteRepository: remoteHomeRepository,
            mockRepository: mockHomeRepository
        )

        let remoteCommunityRepository = RemoteCommunityRepository(apiClient: apiClient)
        let mockCommunityRepository = MockCommunityRepository()
        self.communityRepository = SwitchingCommunityRepository(
            environment: environment,
            remoteRepository: remoteCommunityRepository,
            mockRepository: mockCommunityRepository
        )

        let remoteTopicRepository = RemoteTopicRepository(apiClient: apiClient)
        let mockTopicRepository = MockTopicRepository()
        self.topicRepository = SwitchingTopicRepository(
            environment: environment,
            remoteRepository: remoteTopicRepository,
            mockRepository: mockTopicRepository
        )

        let remoteExpressRepository = RemoteExpressRepository(apiClient: apiClient)
        let mockExpressRepository = MockExpressRepository()
        self.expressRepository = SwitchingExpressRepository(
            environment: environment,
            remoteRepository: remoteExpressRepository,
            mockRepository: mockExpressRepository
        )

        let remoteDeliveryRepository = RemoteDeliveryRepository(apiClient: apiClient)
        let mockDeliveryRepository = MockDeliveryRepository()
        self.deliveryRepository = SwitchingDeliveryRepository(
            environment: environment,
            remoteRepository: remoteDeliveryRepository,
            mockRepository: mockDeliveryRepository
        )

        let remotePhotographRepository = RemotePhotographRepository(apiClient: apiClient)
        let mockPhotographRepository = MockPhotographRepository()
        self.photographRepository = SwitchingPhotographRepository(
            environment: environment,
            remoteRepository: remotePhotographRepository,
            mockRepository: mockPhotographRepository
        )

        let remoteProfileRepository = RemoteProfileRepository(apiClient: apiClient)
        let mockProfileRepository = MockProfileRepository()
        self.profileRepository = SwitchingProfileRepository(
            environment: environment,
            remoteRepository: remoteProfileRepository,
            mockRepository: mockProfileRepository
        )

        let remoteAccountCenterRepository = RemoteAccountCenterRepository(
            apiClient: apiClient
        )
        let mockAccountCenterRepository = MockAccountCenterRepository()
        self.accountCenterRepository = SwitchingAccountCenterRepository(
            environment: environment,
            remoteRepository: remoteAccountCenterRepository,
            mockRepository: mockAccountCenterRepository
        )

        let remoteScheduleRepository = RemoteScheduleRepository(apiClient: apiClient)
        let mockScheduleRepository = MockScheduleRepository()
        self.scheduleRepository = SwitchingScheduleRepository(
            environment: environment,
            remoteRepository: remoteScheduleRepository,
            mockRepository: mockScheduleRepository
        )

        let remoteGradeRepository = RemoteGradeRepository(apiClient: apiClient)
        let mockGradeRepository = MockGradeRepository()
        self.gradeRepository = SwitchingGradeRepository(
            environment: environment,
            remoteRepository: remoteGradeRepository,
            mockRepository: mockGradeRepository
        )

        let remoteCardRepository = RemoteCardRepository(apiClient: apiClient)
        let mockCardRepository = MockCardRepository()
        self.cardRepository = SwitchingCardRepository(
            environment: environment,
            remoteRepository: remoteCardRepository,
            mockRepository: mockCardRepository
        )

        let remoteLibraryRepository = RemoteLibraryRepository(apiClient: apiClient)
        let mockLibraryRepository = MockLibraryRepository()
        self.libraryRepository = SwitchingLibraryRepository(
            environment: environment,
            remoteRepository: remoteLibraryRepository,
            mockRepository: mockLibraryRepository
        )

        let remoteCETRepository = RemoteCETRepository(apiClient: apiClient)
        let mockCETRepository = MockCETRepository()
        self.cetRepository = SwitchingCETRepository(
            environment: environment,
            remoteRepository: remoteCETRepository,
            mockRepository: mockCETRepository
        )

        let remoteEvaluateRepository = RemoteEvaluateRepository(apiClient: apiClient)
        let mockEvaluateRepository = MockEvaluateRepository()
        self.evaluateRepository = SwitchingEvaluateRepository(
            environment: environment,
            remoteRepository: remoteEvaluateRepository,
            mockRepository: mockEvaluateRepository
        )

        let remoteSpareRepository = RemoteSpareRepository(apiClient: apiClient)
        let mockSpareRepository = MockSpareRepository()
        self.spareRepository = SwitchingSpareRepository(
            environment: environment,
            remoteRepository: remoteSpareRepository,
            mockRepository: mockSpareRepository
        )

        let remoteGraduateExamRepository = RemoteGraduateExamRepository(apiClient: apiClient)
        let mockGraduateExamRepository = MockGraduateExamRepository()
        self.graduateExamRepository = SwitchingGraduateExamRepository(
            environment: environment,
            remoteRepository: remoteGraduateExamRepository,
            mockRepository: mockGraduateExamRepository
        )

        let remoteNewsRepository = RemoteNewsRepository(apiClient: apiClient)
        let mockNewsRepository = MockNewsRepository()
        self.newsRepository = SwitchingNewsRepository(
            environment: environment,
            remoteRepository: remoteNewsRepository,
            mockRepository: mockNewsRepository
        )

        let remoteDataCenterRepository = RemoteDataCenterRepository(apiClient: apiClient)
        let mockDataCenterRepository = MockDataCenterRepository()
        self.dataCenterRepository = SwitchingDataCenterRepository(
            environment: environment,
            remoteRepository: remoteDataCenterRepository,
            mockRepository: mockDataCenterRepository
        )

        let remoteMarketplaceRepository = RemoteMarketplaceRepository(apiClient: apiClient)
        let mockMarketplaceRepository = MockMarketplaceRepository()
        self.marketplaceRepository = SwitchingMarketplaceRepository(
            environment: environment,
            remoteRepository: remoteMarketplaceRepository,
            mockRepository: mockMarketplaceRepository
        )

        let remoteLostFoundRepository = RemoteLostFoundRepository(apiClient: apiClient)
        let mockLostFoundRepository = MockLostFoundRepository()
        self.lostFoundRepository = SwitchingLostFoundRepository(
            environment: environment,
            remoteRepository: remoteLostFoundRepository,
            mockRepository: mockLostFoundRepository
        )

        let remoteSecretRepository = RemoteSecretRepository(apiClient: apiClient)
        let mockSecretRepository = MockSecretRepository()
        self.secretRepository = SwitchingSecretRepository(
            environment: environment,
            remoteRepository: remoteSecretRepository,
            mockRepository: mockSecretRepository
        )

        let remoteDatingRepository = RemoteDatingRepository(apiClient: apiClient)
        let mockDatingRepository = MockDatingRepository()
        self.datingRepository = SwitchingDatingRepository(
            environment: environment,
            remoteRepository: remoteDatingRepository,
            mockRepository: mockDatingRepository
        )

        let remoteMessagesRepository = RemoteMessagesRepository(apiClient: apiClient)
        let mockMessagesRepository = MockMessagesRepository()
        self.messagesRepository = SwitchingMessagesRepository(
            environment: environment,
            remoteRepository: remoteMessagesRepository,
            mockRepository: mockMessagesRepository
        )

        authManager.configure(
            repository: authRepository,
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
