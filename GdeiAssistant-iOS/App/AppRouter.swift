import Foundation
import Combine

enum UITestRuntimeOverrides {
    private static let environment = ProcessInfo.processInfo.environment

    static var useMockData: Bool {
        boolValue(for: "GDEI_UI_USE_MOCK")
    }

    static var localeIdentifier: String? {
        stringValue(for: "GDEI_UI_LOCALE")
    }

    static var networkEnvironment: NetworkEnvironment? {
        guard let rawValue = stringValue(for: "GDEI_UI_NETWORK_ENV") else { return nil }
        return NetworkEnvironment(rawValue: rawValue)
    }

    static var useAuthenticatedSession: Bool {
        boolValue(for: "GDEI_UI_AUTHENTICATED")
    }

    static var initialScreen: UITestInitialScreen? {
        guard let rawValue = stringValue(for: "GDEI_UI_INITIAL_SCREEN") else { return nil }
        return UITestInitialScreen(rawValue: rawValue)
    }

    static var failFirstChatImageSend: Bool {
        AppRuntime.isRunningTests && useMockData && boolValue(for: "GDEI_UI_FAIL_FIRST_CHAT_IMAGE")
    }

    private static func stringValue(for key: String) -> String? {
        guard let value = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func boolValue(for key: String) -> Bool {
        guard let value = stringValue(for: key) else { return false }
        return NSString(string: value).boolValue
    }
}

enum UITestInitialScreen: String {
    case home
    case messages
    case marketplace
    case grade
    case conversations
    case profile
}

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
    let socialAssembly: SocialAssembly
    let authenticatedImageLoader: AuthenticatedImageLoader

    // MARK: - Repository accessors (forwarded from assemblies)

    var authRepository: any AuthRepository { coreAssembly.authRepository }
    var homeRepository: any HomeRepository { coreAssembly.homeRepository }

    var scheduleRepository: any ScheduleRepository { campusServicesAssembly.scheduleRepository }
    var gradeRepository: any GradeRepository { campusServicesAssembly.gradeRepository }
    var cardRepository: any CardRepository { campusServicesAssembly.cardRepository }
    var chargeRepository: any ChargeRepository { campusServicesAssembly.chargeRepository }
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
    var socialRepository: any SocialRepository { socialAssembly.socialRepository }
    var socialRealtimeManager: SocialRealtimeManager { socialAssembly.realtimeManager }

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

        let pinningDelegate = CertificatePinningDelegate(
            pinnedHashesByHost: AppConstants.API.certificatePinsByHost
        )
        let pinnedSession = URLSession(
            configuration: .default,
            delegate: pinningDelegate,
            delegateQueue: nil
        )

        let apiClient = APIClient(
            environment: environment,
            session: pinnedSession,
            tokenProvider: { [weak authManager] in
                authManager?.currentToken()
            },
            onUnauthorized: { [weak authManager] in
                authManager?.handleUnauthorized()
            }
        )
        self.authenticatedImageLoader = AuthenticatedImageLoader(
            environment: environment,
            session: pinnedSession,
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
        self.socialAssembly = SocialAssembly(
            apiClient: apiClient,
            environment: environment,
            tokenProvider: { [weak authManager] in
                authManager?.currentToken()
            },
            isLoggedInProvider: { [weak sessionState] in
                sessionState?.isLoggedIn ?? false
            },
            onUnauthorized: { [weak authManager] in
                authManager?.handleUnauthorized()
            }
        )

        let realtimeManager = socialAssembly.realtimeManager
        let imageLoader = authenticatedImageLoader
        authManager.configure(
            repository: coreAssembly.authRepository,
            dataSourceModeProvider: { [weak environment] in
                environment?.dataSourceMode ?? .remote
            },
            onSessionEnded: { [weak realtimeManager, weak imageLoader] in
                realtimeManager?.stop(clearState: true)
                imageLoader?.clearCache()
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
        // UI tests run in their own app process. Use the same store as the
        // localization helper and request language; unit tests keep an isolated suite.
        let isUITestApp = ProcessInfo.processInfo.environment["GDEIASSISTANT_RUNNING_TESTS"] == "1"
        let testDefaults = isUITestApp ? UserDefaults.standard : (UserDefaults(suiteName: suiteName) ?? .standard)
        if !isUITestApp {
            testDefaults.removePersistentDomain(forName: suiteName)
        }
        let preferences = UserPreferences(defaults: testDefaults)
        if let localeIdentifier = UITestRuntimeOverrides.localeIdentifier {
            preferences.selectedLocale = localeIdentifier
        }
        if let networkEnvironment = UITestRuntimeOverrides.networkEnvironment {
            preferences.setNetworkEnvironment(networkEnvironment)
        }
        if UITestRuntimeOverrides.useMockData {
            preferences.setUseMockData(true)
        }
        let container = AppContainer(
            userPreferences: preferences,
            tokenStorage: InMemoryTokenStorage(),
            shouldSkipBootstrap: true
        )
        container.environment.updateNetworkEnvironment(preferences.currentNetworkEnvironment)
        container.environment.updateDataSourceMode(preferences.currentDataSourceMode)
        if UITestRuntimeOverrides.useAuthenticatedSession {
            container.sessionState.markLoggedIn(user: MockFactory.makeUserProfile())
        } else {
            container.sessionState.markLoggedOut()
        }
        container.sessionState.isRestoringSession = false
        return container
    }

    func bootstrapIfNeeded(force: Bool = false) async {
        guard force || !hasBootstrapped else { return }
        hasBootstrapped = true
        guard !shouldSkipBootstrap else {
            sessionState.isRestoringSession = false
            return
        }
        await authManager.restoreSession()
        if sessionState.isLoggedIn {
            socialRealtimeManager.start()
        }
    }

    // MARK: - ViewModel Factories (thin forwarding to assemblies)

    func makeLoginViewModel() -> LoginViewModel {
        coreAssembly.makeLoginViewModel(authManager: authManager)
    }

    func makeHomeViewModel() -> HomeViewModel {
        coreAssembly.makeHomeViewModel()
    }

    // Campus services
    func makeScheduleViewModel() -> ScheduleViewModel { campusServicesAssembly.makeScheduleViewModel() }
    func makeGradeViewModel() -> GradeViewModel { campusServicesAssembly.makeGradeViewModel() }
    func makeCardViewModel() -> CardViewModel { campusServicesAssembly.makeCardViewModel() }
    func makeChargeViewModel() -> ChargeViewModel { campusServicesAssembly.makeChargeViewModel() }
    func makeLibraryViewModel() -> LibraryViewModel { campusServicesAssembly.makeLibraryViewModel() }
    func makeCETViewModel() -> CETViewModel { campusServicesAssembly.makeCETViewModel() }
    func makeEvaluateViewModel() -> EvaluateViewModel { campusServicesAssembly.makeEvaluateViewModel() }
    func makeSpareViewModel() -> SpareViewModel { campusServicesAssembly.makeSpareViewModel() }
    func makeGraduateExamViewModel() -> GraduateExamViewModel { campusServicesAssembly.makeGraduateExamViewModel() }
    func makeNewsViewModel() -> NewsViewModel { campusServicesAssembly.makeNewsViewModel() }

    // Community
    func makeCommunityViewModel() -> CommunityFeedViewModel { communityAssembly.makeCommunityViewModel() }
    func makeTopicViewModel() -> TopicViewModel { communityAssembly.makeTopicViewModel() }
    func makePublishTopicViewModel() -> PublishTopicViewModel { communityAssembly.makePublishTopicViewModel() }
    func makeExpressViewModel() -> ExpressViewModel { communityAssembly.makeExpressViewModel() }
    func makePublishExpressViewModel() -> PublishExpressViewModel { communityAssembly.makePublishExpressViewModel() }
    func makeDeliveryViewModel() -> DeliveryViewModel { communityAssembly.makeDeliveryViewModel() }
    func makePublishDeliveryViewModel() -> PublishDeliveryViewModel { communityAssembly.makePublishDeliveryViewModel() }
    func makePhotographViewModel() -> PhotographViewModel { communityAssembly.makePhotographViewModel() }
    func makePublishPhotographViewModel() -> PublishPhotographViewModel { communityAssembly.makePublishPhotographViewModel() }
    func makePostDetailViewModel(postID: String) -> PostDetailViewModel { communityAssembly.makePostDetailViewModel(postID: postID) }
    func makeTopicFeedViewModel(topicID: String) -> TopicFeedViewModel { communityAssembly.makeTopicFeedViewModel(topicID: topicID) }
    func makeMarketplaceViewModel() -> MarketplaceViewModel { communityAssembly.makeMarketplaceViewModel() }
    func makePublishMarketplaceViewModel() -> PublishMarketplaceViewModel { communityAssembly.makePublishMarketplaceViewModel() }
    func makeLostFoundViewModel() -> LostFoundViewModel { communityAssembly.makeLostFoundViewModel() }
    func makePublishLostFoundViewModel() -> PublishLostFoundViewModel { communityAssembly.makePublishLostFoundViewModel() }
    func makeSecretViewModel() -> SecretViewModel { communityAssembly.makeSecretViewModel() }
    func makePublishSecretViewModel() -> PublishSecretViewModel { communityAssembly.makePublishSecretViewModel() }
    func makeDatingViewModel() -> DatingHallViewModel { communityAssembly.makeDatingViewModel() }
    func makePublishDatingViewModel() -> PublishDatingViewModel { communityAssembly.makePublishDatingViewModel(profileRepository: profileRepository) }
    func makeDatingCenterViewModel(initialTab: DatingCenterTab = .received) -> DatingCenterViewModel { communityAssembly.makeDatingCenterViewModel(initialTab: initialTab) }

    // Profile & account
    func makeProfileViewModel() -> ProfileViewModel { profileAssembly.makeProfileViewModel(sessionState: sessionState) }
    func makeSettingsViewModel() -> SettingsViewModel { profileAssembly.makeSettingsViewModel(environment: environment, preferences: userPreferences) }
    func makePrivacySettingsViewModel() -> PrivacySettingsViewModel { profileAssembly.makePrivacySettingsViewModel() }
    func makeLoginRecordViewModel() -> LoginRecordViewModel { profileAssembly.makeLoginRecordViewModel() }
    func makeBindPhoneViewModel() -> BindPhoneViewModel { profileAssembly.makeBindPhoneViewModel() }
    func makeBindEmailViewModel() -> BindEmailViewModel { profileAssembly.makeBindEmailViewModel() }
    func makeFeedbackViewModel() -> FeedbackViewModel { profileAssembly.makeFeedbackViewModel() }
    func makeDownloadDataViewModel() -> DownloadDataViewModel { profileAssembly.makeDownloadDataViewModel() }
    func makeAvatarEditViewModel() -> AvatarEditViewModel { profileAssembly.makeAvatarEditViewModel(sessionState: sessionState) }
    func makeDeleteAccountViewModel() -> DeleteAccountViewModel { profileAssembly.makeDeleteAccountViewModel() }
    func makeCampusCredentialViewModel() -> CampusCredentialViewModel { profileAssembly.makeCampusCredentialViewModel() }
    func makeMessagesViewModel() -> MessagesViewModel { profileAssembly.makeMessagesViewModel(newsRepository: campusServicesAssembly.newsRepository) }
    func makeSystemNoticeListViewModel() -> SystemNoticeListViewModel { profileAssembly.makeSystemNoticeListViewModel() }
    func makeInteractionMessageListViewModel() -> InteractionMessageListViewModel { profileAssembly.makeInteractionMessageListViewModel() }

    // Social
    func makeSocialUserSearchViewModel() -> SocialUserSearchViewModel { socialAssembly.makeSocialUserSearchViewModel() }
    func makeSocialPublicProfileViewModel(userID: String) -> SocialPublicProfileViewModel { socialAssembly.makeSocialPublicProfileViewModel(userID: userID) }
    func makeSocialRelationshipListViewModel(userID: String, kind: SocialRelationshipKind) -> SocialRelationshipListViewModel {
        socialAssembly.makeSocialRelationshipListViewModel(userID: userID, kind: kind)
    }
    func makeSocialBlockListViewModel() -> SocialBlockListViewModel { socialAssembly.makeSocialBlockListViewModel() }
    func makeDirectMessagePrivacyViewModel() -> DirectMessagePrivacyViewModel { socialAssembly.makeDirectMessagePrivacyViewModel() }
    func makeConversationListViewModel() -> ConversationListViewModel { socialAssembly.makeConversationListViewModel() }
    func makeChatThreadViewModel(conversationID: String) -> ChatThreadViewModel { socialAssembly.makeChatThreadViewModel(conversationID: conversationID) }
    func makeSocialMeSummaryViewModel() -> SocialMeSummaryViewModel { socialAssembly.makeSocialMeSummaryViewModel() }
}
