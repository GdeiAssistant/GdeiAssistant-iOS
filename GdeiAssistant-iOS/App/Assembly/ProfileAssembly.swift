import Foundation

/// Owns repository construction for profile, account center, and messages.
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
}
