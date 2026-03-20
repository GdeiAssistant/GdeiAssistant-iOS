import Foundation

@MainActor
final class RemoteDatingRepository: DatingRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchProfiles(filter: DatingFilter) async throws -> [DatingProfile] {
        let dtos: [DatingProfileDTO] = try await apiClient.get(
            "/dating/profile/area/\(filter.area.rawValue)/start/0",
            requiresAuth: true
        )
        return dtos.map { DatingRemoteMapper.mapProfile($0) }
    }

    func fetchProfileDetail(profileID: String) async throws -> DatingProfileDetail {
        let dto: DatingProfileDetailDTO = try await apiClient.get(
            "/dating/profile/id/\(profileID)",
            requiresAuth: true
        )
        return DatingRemoteMapper.mapProfileDetail(dto)
    }

    func publishProfile(draft: DatingPublishDraft) async throws {
        let fields = [
            FormFieldValue(name: "nickname", value: draft.nickname),
            FormFieldValue(name: "grade", value: String(draft.grade)),
            FormFieldValue(name: "faculty", value: draft.faculty),
            FormFieldValue(name: "hometown", value: draft.hometown),
            FormFieldValue(name: "content", value: draft.content),
            FormFieldValue(name: "area", value: String(draft.area.rawValue))
        ]
        + optionalField(name: "qq", value: draft.qq)
        + optionalField(name: "wechat", value: draft.wechat)

        let files = DatingRemoteMapper.multipartFiles(from: draft.image)

        if files.isEmpty {
            let _: EmptyPayload = try await apiClient.postForm(
                "/dating/profile",
                fields: fields,
                requiresAuth: true
            )
        } else {
            let _: EmptyPayload = try await apiClient.postMultipart(
                "/dating/profile",
                fields: fields,
                files: files,
                requiresAuth: true
            )
        }
    }

    func submitPick(profileID: String, content: String) async throws {
        let _: EmptyPayload = try await apiClient.postForm(
            "/dating/pick",
            fields: [
                FormFieldValue(name: "profileId", value: profileID),
                FormFieldValue(name: "content", value: content)
            ],
            requiresAuth: true
        )
    }

    func fetchReceivedPicks() async throws -> [DatingReceivedPick] {
        let dtos: [DatingPickDTO] = try await apiClient.get("/dating/pick/my/received", requiresAuth: true)
        return dtos.map(DatingRemoteMapper.mapReceivedPick)
    }

    func fetchSentPicks() async throws -> [DatingSentPick] {
        let dtos: [DatingPickDTO] = try await apiClient.get("/dating/pick/my/sent", requiresAuth: true)
        return dtos.map(DatingRemoteMapper.mapSentPick)
    }

    func fetchMyPosts() async throws -> [DatingMyPost] {
        let dtos: [DatingProfileDTO] = try await apiClient.get("/dating/profile/my", requiresAuth: true)
        return dtos.map(DatingRemoteMapper.mapMyPost)
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

    private func optionalField(name: String, value: String?) -> [FormFieldValue] {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return []
        }
        return [FormFieldValue(name: name, value: value)]
    }
}
