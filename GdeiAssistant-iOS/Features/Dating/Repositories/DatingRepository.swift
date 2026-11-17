import Foundation

@MainActor
protocol DatingRepository {
    func fetchProfiles(filter: DatingFilter) async throws -> [DatingProfile]
    func fetchProfileDetail(profileID: String) async throws -> DatingProfileDetail
    func publishProfile(draft: DatingPublishDraft) async throws
    func submitPick(profileID: String, content: String) async throws
    func fetchReceivedPicks() async throws -> [DatingReceivedPick]
    func fetchSentPicks() async throws -> [DatingSentPick]
    func fetchMyPosts() async throws -> [DatingMyPost]
    func updatePickState(pickID: String, state: DatingPickStatus) async throws
    func hideProfile(profileID: String) async throws
}
