import Foundation

/// Owns repository construction for profile, account center, and messages.
@MainActor
struct ProfileAssembly {
    let profileRepository: any ProfileRepository
    let accountCenterRepository: any AccountCenterRepository
    let messagesRepository: any MessagesRepository

    init(apiClient: APIClient, environment: AppEnvironment) {
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

        let remoteMessagesRepository = RemoteMessagesRepository(apiClient: apiClient)
        let mockMessagesRepository = MockMessagesRepository()
        self.messagesRepository = SwitchingMessagesRepository(
            environment: environment,
            remoteRepository: remoteMessagesRepository,
            mockRepository: mockMessagesRepository
        )
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
