import Foundation

/// Owns repository construction for community features:
/// community feed, topic, express, delivery, photograph, marketplace,
/// lost & found, secret, and dating.
@MainActor
struct CommunityAssembly {
    private let environment: AppEnvironment
    private let remoteCommunityRepository: RemoteCommunityRepository
    private let mockCommunityRepository: MockCommunityRepository
    private let remoteTopicRepository: RemoteTopicRepository
    private let mockTopicRepository: MockTopicRepository
    private let remoteExpressRepository: RemoteExpressRepository
    private let mockExpressRepository: MockExpressRepository
    private let remoteDeliveryRepository: RemoteDeliveryRepository
    private let mockDeliveryRepository: MockDeliveryRepository
    private let remotePhotographRepository: RemotePhotographRepository
    private let mockPhotographRepository: MockPhotographRepository
    private let remoteMarketplaceRepository: RemoteMarketplaceRepository
    private let mockMarketplaceRepository: MockMarketplaceRepository
    private let remoteLostFoundRepository: RemoteLostFoundRepository
    private let mockLostFoundRepository: MockLostFoundRepository
    private let remoteSecretRepository: RemoteSecretRepository
    private let mockSecretRepository: MockSecretRepository
    private let remoteDatingRepository: RemoteDatingRepository
    private let mockDatingRepository: MockDatingRepository

    var communityRepository: any CommunityRepository {
        environment.dataSourceMode == .mock ? mockCommunityRepository : remoteCommunityRepository
    }
    var topicRepository: any TopicRepository {
        environment.dataSourceMode == .mock ? mockTopicRepository : remoteTopicRepository
    }
    var expressRepository: any ExpressRepository {
        environment.dataSourceMode == .mock ? mockExpressRepository : remoteExpressRepository
    }
    var deliveryRepository: any DeliveryRepository {
        environment.dataSourceMode == .mock ? mockDeliveryRepository : remoteDeliveryRepository
    }
    var photographRepository: any PhotographRepository {
        environment.dataSourceMode == .mock ? mockPhotographRepository : remotePhotographRepository
    }
    var marketplaceRepository: any MarketplaceRepository {
        environment.dataSourceMode == .mock ? mockMarketplaceRepository : remoteMarketplaceRepository
    }
    var lostFoundRepository: any LostFoundRepository {
        environment.dataSourceMode == .mock ? mockLostFoundRepository : remoteLostFoundRepository
    }
    var secretRepository: any SecretRepository {
        environment.dataSourceMode == .mock ? mockSecretRepository : remoteSecretRepository
    }
    var datingRepository: any DatingRepository {
        environment.dataSourceMode == .mock ? mockDatingRepository : remoteDatingRepository
    }

    init(apiClient: APIClient, environment: AppEnvironment) {
        self.environment = environment
        self.remoteCommunityRepository = RemoteCommunityRepository(apiClient: apiClient)
        self.mockCommunityRepository = MockCommunityRepository()
        self.remoteTopicRepository = RemoteTopicRepository(apiClient: apiClient)
        self.mockTopicRepository = MockTopicRepository()
        self.remoteExpressRepository = RemoteExpressRepository(apiClient: apiClient)
        self.mockExpressRepository = MockExpressRepository()
        self.remoteDeliveryRepository = RemoteDeliveryRepository(apiClient: apiClient)
        self.mockDeliveryRepository = MockDeliveryRepository()
        self.remotePhotographRepository = RemotePhotographRepository(apiClient: apiClient)
        self.mockPhotographRepository = MockPhotographRepository()
        self.remoteMarketplaceRepository = RemoteMarketplaceRepository(apiClient: apiClient)
        self.mockMarketplaceRepository = MockMarketplaceRepository()
        self.remoteLostFoundRepository = RemoteLostFoundRepository(apiClient: apiClient)
        self.mockLostFoundRepository = MockLostFoundRepository()
        self.remoteSecretRepository = RemoteSecretRepository(apiClient: apiClient)
        self.mockSecretRepository = MockSecretRepository()
        self.remoteDatingRepository = RemoteDatingRepository(apiClient: apiClient)
        self.mockDatingRepository = MockDatingRepository()
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
