import Foundation

@MainActor
protocol DatingRepository {
    func fetchReceivedPicks() async throws -> [DatingReceivedPick]
    func fetchSentPicks() async throws -> [DatingSentPick]
    func fetchMyPosts() async throws -> [DatingMyPost]
    func updatePickState(pickID: String, state: DatingPickStatus) async throws
    func hideProfile(profileID: String) async throws
}

@MainActor
final class SwitchingDatingRepository: DatingRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any DatingRepository
    private let mockRepository: any DatingRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any DatingRepository,
        mockRepository: any DatingRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchReceivedPicks() async throws -> [DatingReceivedPick] {
        try await currentRepository.fetchReceivedPicks()
    }

    func fetchSentPicks() async throws -> [DatingSentPick] {
        try await currentRepository.fetchSentPicks()
    }

    func fetchMyPosts() async throws -> [DatingMyPost] {
        try await currentRepository.fetchMyPosts()
    }

    func updatePickState(pickID: String, state: DatingPickStatus) async throws {
        try await currentRepository.updatePickState(pickID: pickID, state: state)
    }

    func hideProfile(profileID: String) async throws {
        try await currentRepository.hideProfile(profileID: profileID)
    }

    private var currentRepository: any DatingRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
