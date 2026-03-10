import Foundation

@MainActor
protocol DatingRepository {
    func fetchProfiles(filter: DatingFilter) async throws -> [DatingProfile]
    func fetchProfile(profileID: String) async throws -> DatingProfile
    func fetchProfileDetail(profileID: String) async throws -> DatingProfileDetail
    func fetchReceivedPicks(start: Int) async throws -> [DatingReceivedPick]
    func fetchSentPicks() async throws -> [DatingSentPick]
    func fetchMyPosts() async throws -> [DatingMyPost]
    func publish(draft: DatingPublishDraft) async throws
    func sendPick(profileID: String, content: String) async throws
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

    func fetchProfiles(filter: DatingFilter) async throws -> [DatingProfile] {
        try await currentRepository.fetchProfiles(filter: filter)
    }

    func fetchProfile(profileID: String) async throws -> DatingProfile {
        try await currentRepository.fetchProfile(profileID: profileID)
    }

    func fetchProfileDetail(profileID: String) async throws -> DatingProfileDetail {
        try await currentRepository.fetchProfileDetail(profileID: profileID)
    }

    func fetchReceivedPicks(start: Int) async throws -> [DatingReceivedPick] {
        try await currentRepository.fetchReceivedPicks(start: start)
    }

    func fetchSentPicks() async throws -> [DatingSentPick] {
        try await currentRepository.fetchSentPicks()
    }

    func fetchMyPosts() async throws -> [DatingMyPost] {
        try await currentRepository.fetchMyPosts()
    }

    func publish(draft: DatingPublishDraft) async throws {
        try await currentRepository.publish(draft: draft)
    }

    func sendPick(profileID: String, content: String) async throws {
        try await currentRepository.sendPick(profileID: profileID, content: content)
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
