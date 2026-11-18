import Foundation

/// Owns repository construction for community features:
/// community feed, topic, express, delivery, photograph, marketplace,
/// lost & found, secret, and dating.
@MainActor
struct CommunityAssembly {
    private let environment: AppEnvironment
    private let remoteCommunityRepository: RemoteCommunityRepository
    private let remoteTopicRepository: RemoteTopicRepository
    private let remoteExpressRepository: RemoteExpressRepository
    private let remoteDeliveryRepository: RemoteDeliveryRepository
    private let remotePhotographRepository: RemotePhotographRepository
    private let remoteMarketplaceRepository: RemoteMarketplaceRepository
    private let remoteLostFoundRepository: RemoteLostFoundRepository
    private let remoteSecretRepository: RemoteSecretRepository
    private let remoteDatingRepository: RemoteDatingRepository
    #if DEBUG
    private let mockCommunityRepository: MockCommunityRepository
    private let mockTopicRepository: MockTopicRepository
    private let mockExpressRepository: MockExpressRepository
    private let mockDeliveryRepository: MockDeliveryRepository
    private let mockPhotographRepository: MockPhotographRepository
    private let mockMarketplaceRepository: MockMarketplaceRepository
    private let mockLostFoundRepository: MockLostFoundRepository
    private let mockSecretRepository: MockSecretRepository
    private let mockDatingRepository: MockDatingRepository
    #endif

    var communityRepository: any CommunityRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockCommunityRepository : remoteCommunityRepository
        #else
        return remoteCommunityRepository
        #endif
    }
    var topicRepository: any TopicRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockTopicRepository : remoteTopicRepository
        #else
        return remoteTopicRepository
        #endif
    }
    var expressRepository: any ExpressRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockExpressRepository : remoteExpressRepository
        #else
        return remoteExpressRepository
        #endif
    }
    var deliveryRepository: any DeliveryRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockDeliveryRepository : remoteDeliveryRepository
        #else
        return remoteDeliveryRepository
        #endif
    }
    var photographRepository: any PhotographRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockPhotographRepository : remotePhotographRepository
        #else
        return remotePhotographRepository
        #endif
    }
    var marketplaceRepository: any MarketplaceRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockMarketplaceRepository : remoteMarketplaceRepository
        #else
        return remoteMarketplaceRepository
        #endif
    }
    var lostFoundRepository: any LostFoundRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockLostFoundRepository : remoteLostFoundRepository
        #else
        return remoteLostFoundRepository
        #endif
    }
    var secretRepository: any SecretRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockSecretRepository : remoteSecretRepository
        #else
        return remoteSecretRepository
        #endif
    }
    var datingRepository: any DatingRepository {
        #if DEBUG
        return environment.dataSourceMode == .mock ? mockDatingRepository : remoteDatingRepository
        #else
        return remoteDatingRepository
        #endif
    }

    init(apiClient: APIClient, environment: AppEnvironment) {
        self.environment = environment
        self.remoteCommunityRepository = RemoteCommunityRepository(apiClient: apiClient)
        self.remoteTopicRepository = RemoteTopicRepository(apiClient: apiClient)
        self.remoteExpressRepository = RemoteExpressRepository(apiClient: apiClient)
        self.remoteDeliveryRepository = RemoteDeliveryRepository(apiClient: apiClient)
        self.remotePhotographRepository = RemotePhotographRepository(apiClient: apiClient)
        self.remoteMarketplaceRepository = RemoteMarketplaceRepository(apiClient: apiClient)
        self.remoteLostFoundRepository = RemoteLostFoundRepository(apiClient: apiClient)
        self.remoteSecretRepository = RemoteSecretRepository(apiClient: apiClient)
        self.remoteDatingRepository = RemoteDatingRepository(apiClient: apiClient)
        #if DEBUG
        self.mockCommunityRepository = MockCommunityRepository()
        self.mockTopicRepository = MockTopicRepository()
        self.mockExpressRepository = MockExpressRepository()
        self.mockDeliveryRepository = MockDeliveryRepository()
        self.mockPhotographRepository = MockPhotographRepository()
        self.mockMarketplaceRepository = MockMarketplaceRepository()
        self.mockLostFoundRepository = MockLostFoundRepository()
        self.mockSecretRepository = MockSecretRepository()
        self.mockDatingRepository = MockDatingRepository()
        #endif
    }

    // MARK: - ViewModel Factories

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

    func makePublishSecretViewModel() -> PublishSecretViewModel {
        PublishSecretViewModel()
    }

    func makeDatingViewModel() -> DatingHallViewModel {
        DatingHallViewModel(repository: datingRepository)
    }

    func makePublishDatingViewModel(profileRepository: any ProfileRepository) -> PublishDatingViewModel {
        PublishDatingViewModel(profileRepository: profileRepository)
    }

    func makeDatingCenterViewModel(initialTab: DatingCenterTab = .received) -> DatingCenterViewModel {
        let viewModel = DatingCenterViewModel(repository: datingRepository)
        viewModel.selectedTab = initialTab
        return viewModel
    }
}
