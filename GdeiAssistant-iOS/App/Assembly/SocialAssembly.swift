import Foundation

/// Owns social / direct-message repositories, realtime manager, and related ViewModel factories.
@MainActor
struct SocialAssembly {
    let socialRepository: any SocialRepository
    let realtimeManager: SocialRealtimeManager
    private let tokenProvider: @MainActor () -> String?

    init(
        apiClient: APIClient,
        environment: AppEnvironment,
        tokenProvider: @escaping () -> String?,
        isLoggedInProvider: @escaping () -> Bool,
        onUnauthorized: @escaping () -> Void
    ) {
        self.tokenProvider = tokenProvider
        let remoteSocialRepository = RemoteSocialRepository(apiClient: apiClient)
        let mockSocialRepository = MockSocialRepository()
        self.socialRepository = SwitchingSocialRepository(
            environment: environment,
            remoteRepository: remoteSocialRepository,
            mockRepository: mockSocialRepository
        )
        self.realtimeManager = SocialRealtimeManager(
            environment: environment,
            tokenProvider: tokenProvider,
            isLoggedInProvider: isLoggedInProvider,
            onUnauthorized: onUnauthorized
        )
    }

    func makeSocialUserSearchViewModel() -> SocialUserSearchViewModel {
        SocialUserSearchViewModel(repository: socialRepository)
    }

    func makeSocialPublicProfileViewModel(userID: String) -> SocialPublicProfileViewModel {
        SocialPublicProfileViewModel(userID: userID, repository: socialRepository)
    }

    func makeSocialRelationshipListViewModel(
        userID: String,
        kind: SocialRelationshipKind
    ) -> SocialRelationshipListViewModel {
        SocialRelationshipListViewModel(userID: userID, kind: kind, repository: socialRepository)
    }

    func makeSocialBlockListViewModel() -> SocialBlockListViewModel {
        SocialBlockListViewModel(repository: socialRepository)
    }

    func makeDirectMessagePrivacyViewModel() -> DirectMessagePrivacyViewModel {
        DirectMessagePrivacyViewModel(repository: socialRepository)
    }

    func makeConversationListViewModel() -> ConversationListViewModel {
        ConversationListViewModel(repository: socialRepository, realtimeManager: realtimeManager)
    }

    func makeChatThreadViewModel(conversationID: String) -> ChatThreadViewModel {
        ChatThreadViewModel(
            conversationID: conversationID,
            repository: socialRepository,
            realtimeManager: realtimeManager,
            tokenProvider: tokenProvider
        )
    }

    func makeSocialMeSummaryViewModel() -> SocialMeSummaryViewModel {
        SocialMeSummaryViewModel(repository: socialRepository)
    }
}
