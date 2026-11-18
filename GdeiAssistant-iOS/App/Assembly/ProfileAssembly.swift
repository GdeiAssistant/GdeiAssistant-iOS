import Foundation

/// Owns repository construction for profile, account center, and messages.
@MainActor
struct ProfileAssembly {
    private let environment: AppEnvironment
    private let remoteProfileRepository: RemoteProfileRepository
    private let remoteAccountCenterRepository: RemoteAccountCenterRepository
    private let remoteMessagesRepository: RemoteMessagesRepository
    #if DEBUG
    private let mockProfileRepository: MockProfileRepository
    private let mockAccountCenterRepository: MockAccountCenterRepository
    private let mockMessagesRepository: MockMessagesRepository
    #endif

    func profileRepository(for mode: DataSourceMode) -> any ProfileRepository {
        #if DEBUG
        return mode == .mock ? mockProfileRepository : remoteProfileRepository
        #else
        return remoteProfileRepository
        #endif
    }

    var profileRepository: any ProfileRepository {
        profileRepository(for: environment.dataSourceMode)
    }
    var accountCenterRepository: any AccountCenterRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockAccountCenterRepository : remoteAccountCenterRepository
        #else
        return remoteAccountCenterRepository
        #endif
    }
    func messagesRepository(for mode: DataSourceMode) -> any MessagesRepository {
        #if DEBUG
        return mode == .mock ? mockMessagesRepository : remoteMessagesRepository
        #else
        return remoteMessagesRepository
        #endif
    }

    var messagesRepository: any MessagesRepository {
        messagesRepository(for: environment.dataSourceMode)
    }

    init(apiClient: APIClient, environment: AppEnvironment) {
        self.environment = environment
        self.remoteProfileRepository = RemoteProfileRepository(apiClient: apiClient)
        self.remoteAccountCenterRepository = RemoteAccountCenterRepository(apiClient: apiClient)
        self.remoteMessagesRepository = RemoteMessagesRepository(apiClient: apiClient)
        #if DEBUG
        self.mockProfileRepository = MockProfileRepository()
        self.mockAccountCenterRepository = MockAccountCenterRepository()
        self.mockMessagesRepository = MockMessagesRepository()
        #endif
    }

    // MARK: - ViewModel Factories

    func makeProfileViewModel(sessionState: SessionState) -> ProfileViewModel {
        ProfileViewModel(repository: profileRepository, sessionState: sessionState)
    }

    func makeSettingsViewModel(environment: AppEnvironment, preferences: UserPreferences) -> SettingsViewModel {
        SettingsViewModel(environment: environment, preferences: preferences)
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

    func makeAvatarEditViewModel(sessionState: SessionState) -> AvatarEditViewModel {
        AvatarEditViewModel(repository: accountCenterRepository, sessionState: sessionState)
    }

    func makeDeleteAccountViewModel() -> DeleteAccountViewModel {
        DeleteAccountViewModel(repository: accountCenterRepository)
    }

    func makeCampusCredentialViewModel() -> CampusCredentialViewModel {
        CampusCredentialViewModel(repository: accountCenterRepository)
    }

    func makeMessagesViewModel(newsRepository: any NewsRepository) -> MessagesViewModel {
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
