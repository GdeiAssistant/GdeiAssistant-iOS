import Foundation

/// Owns repository construction for profile, account center, and messages.
@MainActor
struct ProfileAssembly {
    private let environment: AppEnvironment
    private let remoteProfileRepository: RemoteProfileRepository
    private let mockProfileRepository: MockProfileRepository
    private let remoteAccountCenterRepository: RemoteAccountCenterRepository
    private let mockAccountCenterRepository: MockAccountCenterRepository
    private let remoteMessagesRepository: RemoteMessagesRepository
    private let mockMessagesRepository: MockMessagesRepository

    var profileRepository: any ProfileRepository {
        environment.dataSourceMode == .mock ? mockProfileRepository : remoteProfileRepository
    }
    var accountCenterRepository: any AccountCenterRepository {
        environment.dataSourceMode == .mock ? mockAccountCenterRepository : remoteAccountCenterRepository
    }
    var messagesRepository: any MessagesRepository {
        environment.dataSourceMode == .mock ? mockMessagesRepository : remoteMessagesRepository
    }

    init(apiClient: APIClient, environment: AppEnvironment) {
        self.environment = environment
        self.remoteProfileRepository = RemoteProfileRepository(apiClient: apiClient)
        self.mockProfileRepository = MockProfileRepository()
        self.remoteAccountCenterRepository = RemoteAccountCenterRepository(apiClient: apiClient)
        self.mockAccountCenterRepository = MockAccountCenterRepository()
        self.remoteMessagesRepository = RemoteMessagesRepository(apiClient: apiClient)
        self.mockMessagesRepository = MockMessagesRepository()
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
