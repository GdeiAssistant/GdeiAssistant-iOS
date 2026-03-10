import Foundation

@MainActor
final class RemoteDatingRepository: DatingRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchProfiles(filter: DatingFilter) async throws -> [DatingProfile] {
        let area = DatingRemoteMapper.area(from: filter)
        let dtos: [DatingProfileDTO] = try await apiClient.get("/dating/profile/area/\(area)/start/0", requiresAuth: true)
        return try await enrichProfiles(dtos)
    }

    func fetchProfile(profileID: String) async throws -> DatingProfile {
        try await fetchProfileDetail(profileID: profileID).profile
    }

    func fetchProfileDetail(profileID: String) async throws -> DatingProfileDetail {
        let dto: DatingProfileDetailDTO = try await apiClient.get("/dating/profile/id/\(profileID)", requiresAuth: true)
        let detail = try DatingRemoteMapper.mapDetail(dto)
        guard detail.profile.imageURL == nil else {
            return detail
        }

        let fallbackImageURL = try? await fetchPictureURL(profileID: profileID)
        guard let fallbackImageURL else {
            return detail
        }

        return DatingProfileDetail(
            profile: DatingProfile(
                id: detail.profile.id,
                nickname: detail.profile.nickname,
                headline: detail.profile.headline,
                college: detail.profile.college,
                major: detail.profile.major,
                grade: detail.profile.grade,
                tags: detail.profile.tags,
                bio: detail.profile.bio,
                imageURL: fallbackImageURL,
                hometown: detail.profile.hometown,
                qq: detail.profile.qq,
                wechat: detail.profile.wechat,
                isContactVisible: detail.profile.isContactVisible,
                area: detail.profile.area
            ),
            isPickNotAvailable: detail.isPickNotAvailable
        )
    }

    func fetchReceivedPicks(start: Int) async throws -> [DatingReceivedPick] {
        let dtos: [DatingMessageDTO] = try await apiClient.get("/dating/message/start/\(max(start, 0))", requiresAuth: true)
        return try await enrichReceivedPicks(dtos)
    }

    func fetchSentPicks() async throws -> [DatingSentPick] {
        let dtos: [DatingPickDTO] = try await apiClient.get("/dating/pick/my/sent", requiresAuth: true)
        return try await enrichSentPicks(dtos)
    }

    func fetchMyPosts() async throws -> [DatingMyPost] {
        let dtos: [DatingProfileDTO] = try await apiClient.get("/dating/profile/my", requiresAuth: true)
        return try await enrichMyPosts(dtos)
    }

    func publish(draft: DatingPublishDraft) async throws {
        let _: EmptyPayload = try await apiClient.postMultipart(
            "/dating/profile",
            fields: DatingRemoteMapper.publishFields(for: draft),
            files: DatingRemoteMapper.publishFiles(for: draft),
            requiresAuth: true
        )
    }

    func sendPick(profileID: String, content: String) async throws {
        let _: EmptyPayload = try await apiClient.postForm(
            "/dating/pick",
            fields: [
                FormFieldValue(name: "profileId", value: profileID),
                FormFieldValue(name: "content", value: content)
            ],
            requiresAuth: true
        )
    }

    func updatePickState(pickID: String, state: DatingPickStatus) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/dating/pick/id/\(pickID)",
            queryItems: [URLQueryItem(name: "state", value: String(state.rawValue))],
            requiresAuth: true
        )
    }

    func hideProfile(profileID: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/dating/profile/id/\(profileID)/state",
            queryItems: [URLQueryItem(name: "state", value: "0")],
            requiresAuth: true
        )
    }

    private func enrichProfiles(_ dtos: [DatingProfileDTO]) async throws -> [DatingProfile] {
        let mappedProfiles = DatingRemoteMapper.mapProfiles(dtos)
        var enrichedProfiles = [DatingProfile]()
        enrichedProfiles.reserveCapacity(mappedProfiles.count)

        for (index, profile) in mappedProfiles.enumerated() {
            let dto = dtos[index]
            var fallbackImageURL = profile.imageURL
            if fallbackImageURL == nil {
                fallbackImageURL = try? await fetchPictureURL(profileID: dto.profileId)
            }
            enrichedProfiles.append(
                DatingProfile(
                    id: profile.id,
                    nickname: profile.nickname,
                    headline: profile.headline,
                    college: profile.college,
                    major: profile.major,
                    grade: profile.grade,
                    tags: profile.tags,
                    bio: profile.bio,
                    imageURL: fallbackImageURL,
                    hometown: profile.hometown,
                    qq: profile.qq,
                    wechat: profile.wechat,
                    isContactVisible: profile.isContactVisible,
                    area: profile.area
                )
            )
        }

        return enrichedProfiles
    }

    private func enrichReceivedPicks(_ dtos: [DatingMessageDTO]) async throws -> [DatingReceivedPick] {
        var items = [DatingReceivedPick]()
        items.reserveCapacity(dtos.count)

        for dto in dtos {
            let mapped = DatingRemoteMapper.mapReceivedPick(dto)
            let profileID = dto.datingPick?.datingProfile?.profileId ?? dto.roommatePick?.roommateProfile?.profileId
            var fallbackAvatarURL = mapped.avatarURL
            if fallbackAvatarURL == nil {
                fallbackAvatarURL = try? await fetchPictureURL(profileID: profileID)
            }
            items.append(
                DatingReceivedPick(
                    id: mapped.id,
                    senderName: mapped.senderName,
                    content: mapped.content,
                    time: mapped.time,
                    status: mapped.status,
                    avatarURL: fallbackAvatarURL
                )
            )
        }

        return items
    }

    private func enrichSentPicks(_ dtos: [DatingPickDTO]) async throws -> [DatingSentPick] {
        var items = [DatingSentPick]()
        items.reserveCapacity(dtos.count)

        for dto in dtos {
            let mapped = DatingRemoteMapper.mapSentPick(dto)
            let profileID = dto.datingProfile?.profileId ?? dto.roommateProfile?.profileId
            var fallbackAvatarURL = mapped.targetAvatarURL
            if fallbackAvatarURL == nil {
                fallbackAvatarURL = try? await fetchPictureURL(profileID: profileID)
            }
            items.append(
                DatingSentPick(
                    id: mapped.id,
                    targetName: mapped.targetName,
                    content: mapped.content,
                    status: mapped.status,
                    targetQq: mapped.targetQq,
                    targetWechat: mapped.targetWechat,
                    targetAvatarURL: fallbackAvatarURL
                )
            )
        }

        return items
    }

    private func enrichMyPosts(_ dtos: [DatingProfileDTO]) async throws -> [DatingMyPost] {
        var items = [DatingMyPost]()
        items.reserveCapacity(dtos.count)

        for dto in dtos {
            let mapped = DatingRemoteMapper.mapMyPost(dto)
            var fallbackImageURL = mapped.imageURL
            if fallbackImageURL == nil {
                fallbackImageURL = try? await fetchPictureURL(profileID: dto.profileId)
            }
            items.append(
                DatingMyPost(
                    id: mapped.id,
                    name: mapped.name,
                    imageURL: fallbackImageURL,
                    publishTime: mapped.publishTime,
                    grade: mapped.grade,
                    faculty: mapped.faculty,
                    hometown: mapped.hometown,
                    area: mapped.area,
                    state: mapped.state
                )
            )
        }

        return items
    }

    private func fetchPictureURL(profileID: Int?) async throws -> String? {
        guard let profileID else { return nil }
        let pictureURL: String = try await apiClient.get("/dating/profile/id/\(profileID)/picture", requiresAuth: true)
        return RemoteMapperSupport.sanitizedText(pictureURL)
    }

    private func fetchPictureURL(profileID: String) async throws -> String? {
        let pictureURL: String = try await apiClient.get("/dating/profile/id/\(profileID)/picture", requiresAuth: true)
        return RemoteMapperSupport.sanitizedText(pictureURL)
    }
}
