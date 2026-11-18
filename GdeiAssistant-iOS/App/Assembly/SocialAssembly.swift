import Foundation

/// Owns social / direct-message repositories, realtime manager, and related ViewModel factories.
@MainActor
struct SocialAssembly {
    private let environment: AppEnvironment
    private let remoteSocialRepository: RemoteSocialRepository
    #if DEBUG
    private let mockSocialRepository: MockSocialRepository
    #endif
    let realtimeManager: SocialRealtimeManager
    private let tokenProvider: @MainActor () -> String?

    var socialRepository: any SocialRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockSocialRepository : remoteSocialRepository
        #else
        return remoteSocialRepository
        #endif
    }

    init(
        apiClient: APIClient,
        environment: AppEnvironment,
        tokenProvider: @escaping () -> String?,
        isLoggedInProvider: @escaping () -> Bool,
        onUnauthorized: @escaping () -> Void,
        sessionDelegate: URLSessionDelegate? = nil
    ) {
        self.environment = environment
        self.tokenProvider = tokenProvider
        self.remoteSocialRepository = RemoteSocialRepository(apiClient: apiClient)
        #if DEBUG
        self.mockSocialRepository = MockSocialRepository(
            failFirstImageSend: UITestRuntimeOverrides.failFirstChatImageSend
        )
        #endif
        self.realtimeManager = SocialRealtimeManager(
            environment: environment,
            tokenProvider: tokenProvider,
            isLoggedInProvider: isLoggedInProvider,
            onUnauthorized: onUnauthorized,
            sessionDelegate: sessionDelegate
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
