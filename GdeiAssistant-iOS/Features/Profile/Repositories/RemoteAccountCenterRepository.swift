import Foundation

@MainActor
final class RemoteAccountCenterRepository: AccountCenterRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchPrivacySettings() async throws -> PrivacySettings {
        let dto: PrivacySettingsDTO = try await apiClient.get("/privacy", requiresAuth: true)
        return AccountCenterRemoteMapper.mapPrivacySettings(dto)
    }

    func updatePrivacySettings(_ settings: PrivacySettings) async throws -> PrivacySettings {
        let dto = AccountCenterRemoteMapper.mapPrivacyDTO(settings)
        let _: EmptyPayload = try await apiClient.post("/privacy", body: dto, requiresAuth: true)
        return settings
    }

    func fetchLoginRecords() async throws -> [LoginRecordItem] {
        let dtos: [LoginRecordDTO] = try await apiClient.get("/ip/start/0/size/20", requiresAuth: true)
        return AccountCenterRemoteMapper.mapLoginRecords(dtos)
    }

    func fetchPhoneAttributions() async throws -> [PhoneAttribution] {
        let dtos: [PhoneAttributionDTO] = try await apiClient.get("/phone/attribution", requiresAuth: true)
        return AccountCenterRemoteMapper.mapPhoneAttributions(dtos)
    }

    func fetchPhoneStatus() async throws -> ContactBindingStatus {
        do {
            let dto: PhoneStatusDTO = try await apiClient.get("/phone/status", requiresAuth: true)
            return AccountCenterRemoteMapper.mapPhoneStatus(dto)
        } catch NetworkError.noData {
            return AccountCenterRemoteMapper.mapPhoneStatus(nil)
        }
    }

    func sendPhoneVerification(areaCode: Int, phone: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/phone/verification",
            queryItems: [
                URLQueryItem(name: "code", value: String(areaCode)),
                URLQueryItem(name: "phone", value: phone)
            ],
            requiresAuth: true
        )
    }

    func bindPhone(request: PhoneBindRequest) async throws -> ContactBindingStatus {
        let _: EmptyPayload = try await apiClient.post(
            "/phone/attach",
            queryItems: [
                URLQueryItem(name: "code", value: String(request.areaCode)),
                URLQueryItem(name: "phone", value: request.phone),
                URLQueryItem(name: "randomCode", value: request.randomCode)
            ],
            requiresAuth: true
        )
        return AccountCenterRemoteMapper.mapPhoneStatus(
            PhoneStatusDTO(username: nil, phone: request.phone, code: request.areaCode)
        )
    }

    func unbindPhone() async throws -> ContactBindingStatus {
        let _: EmptyPayload = try await apiClient.post("/phone/unattach", requiresAuth: true)
        return AccountCenterRemoteMapper.mapPhoneStatus(nil)
    }

    func fetchEmailStatus() async throws -> ContactBindingStatus {
        do {
            let value: String = try await apiClient.get("/email/status", requiresAuth: true)
            return AccountCenterRemoteMapper.mapEmailStatus(value)
        } catch NetworkError.noData {
            return AccountCenterRemoteMapper.mapEmailStatus(nil)
        }
    }

    func sendEmailVerification(email: String) async throws {
        let _: EmptyPayload = try await apiClient.post(
            "/email/verification",
            queryItems: [URLQueryItem(name: "email", value: email)],
            requiresAuth: true
        )
    }

    func bindEmail(email: String, randomCode: String) async throws -> ContactBindingStatus {
        let _: EmptyPayload = try await apiClient.post(
            "/email/bind",
            queryItems: [
                URLQueryItem(name: "email", value: email),
                URLQueryItem(name: "randomCode", value: randomCode)
            ],
            requiresAuth: true
        )
        return AccountCenterRemoteMapper.mapEmailStatus(email)
    }

    func unbindEmail() async throws -> ContactBindingStatus {
        let _: EmptyPayload = try await apiClient.post("/email/unbind", requiresAuth: true)
        return AccountCenterRemoteMapper.mapEmailStatus(nil)
    }

    func submitFeedback(_ submission: FeedbackSubmission) async throws {
        let dto = AccountCenterRemoteMapper.mapFeedbackDTO(submission)
        let _: EmptyPayload = try await apiClient.post("/feedback", body: dto, requiresAuth: true)
    }

    func fetchDownloadStatus() async throws -> DownloadDataStatus {
        let state: Int = try await apiClient.get("/userdata/state", requiresAuth: true)
        return AccountCenterRemoteMapper.mapExportStatus(state)
    }

    func startDataExport() async throws -> DownloadDataStatus {
        let _: EmptyPayload = try await apiClient.post("/userdata/export", requiresAuth: true)
        return AccountCenterRemoteMapper.mapExportStatus(DownloadExportState.exporting.rawValue)
    }

    func fetchDownloadURL() async throws -> DownloadDataStatus {
        let url: String = try await apiClient.post("/userdata/download", requiresAuth: true)
        return AccountCenterRemoteMapper.mapExportStatus(DownloadExportState.exported.rawValue, downloadURL: url)
    }

    func fetchAvatarState() async throws -> AvatarState {
        do {
            let url: String = try await apiClient.get("/profile/avatar", requiresAuth: true)
            return AccountCenterRemoteMapper.mapAvatarState(url)
        } catch NetworkError.noData {
            return AccountCenterRemoteMapper.mapAvatarState(nil)
        }
    }

    func uploadAvatar(_ avatar: UploadImageAsset) async throws -> AvatarState {
        let _: EmptyPayload = try await apiClient.postMultipart(
            "/profile/avatar",
            fields: [],
            files: AccountCenterRemoteMapper.makeAvatarUploadFiles(avatar),
            requiresAuth: true
        )
        return try await fetchAvatarState()
    }

    func deleteAvatar() async throws -> AvatarState {
        let _: EmptyPayload = try await apiClient.delete("/profile/avatar", requiresAuth: true)
        return AvatarState(url: nil)
    }

    func deleteAccount(password: String) async throws {
        let _: EmptyPayload = try await apiClient.postForm(
            "/close/submit",
            fields: [FormFieldValue(name: "password", value: password)],
            requiresAuth: true
        )
    }
}
