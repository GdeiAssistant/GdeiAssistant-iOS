import Foundation

/// Owns repository construction for community features:
/// community feed, topic, express, delivery, photograph, marketplace,
/// lost & found, secret, and dating.
struct CommunityAssembly {
    let communityRepository: any CommunityRepository
    let topicRepository: any TopicRepository
    let expressRepository: any ExpressRepository
    let deliveryRepository: any DeliveryRepository
    let photographRepository: any PhotographRepository
    let marketplaceRepository: any MarketplaceRepository
    let lostFoundRepository: any LostFoundRepository
    let secretRepository: any SecretRepository
    let datingRepository: any DatingRepository

    init(apiClient: APIClient, environment: AppEnvironment) {
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
    }
}
