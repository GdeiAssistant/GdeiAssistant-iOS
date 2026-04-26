import Foundation

@MainActor
protocol AccountCenterRepository {
    func fetchPrivacySettings() async throws -> PrivacySettings
    func updatePrivacySettings(_ settings: PrivacySettings) async throws -> PrivacySettings
    func fetchLoginRecords() async throws -> [LoginRecordItem]
    func fetchPhoneAttributions() async throws -> [PhoneAttribution]
    func fetchPhoneStatus() async throws -> ContactBindingStatus
    func sendPhoneVerification(areaCode: Int, phone: String) async throws
    func bindPhone(request: PhoneBindRequest) async throws -> ContactBindingStatus
    func unbindPhone() async throws -> ContactBindingStatus
    func fetchEmailStatus() async throws -> ContactBindingStatus
    func sendEmailVerification(email: String) async throws
    func bindEmail(email: String, randomCode: String) async throws -> ContactBindingStatus
    func unbindEmail() async throws -> ContactBindingStatus
    func submitFeedback(_ submission: FeedbackSubmission) async throws
    func fetchDownloadStatus() async throws -> DownloadDataStatus
    func startDataExport() async throws -> DownloadDataStatus
    func fetchDownloadURL() async throws -> DownloadDataStatus
    func fetchAvatarState() async throws -> AvatarState
    func uploadAvatar(_ avatar: UploadImageAsset) async throws -> AvatarState
    func deleteAvatar() async throws -> AvatarState
    func deleteAccount(password: String) async throws
    func fetchCampusCredentialStatus() async throws -> CampusCredentialStatus
    func recordCampusCredentialConsent(metadata: CampusCredentialConsentMetadata) async throws -> CampusCredentialStatus
    func revokeCampusCredentialConsent() async throws -> CampusCredentialStatus
    func deleteCampusCredential() async throws -> CampusCredentialStatus
    func setQuickAuthEnabled(_ enabled: Bool) async throws -> CampusCredentialStatus
}

@MainActor
final class SwitchingAccountCenterRepository: AccountCenterRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any AccountCenterRepository
    private let mockRepository: any AccountCenterRepository

    init(
        environment: AppEnvironment,
        remoteRepository: any AccountCenterRepository,
        mockRepository: any AccountCenterRepository
    ) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchPrivacySettings() async throws -> PrivacySettings {
        try await currentRepository.fetchPrivacySettings()
    }

    func updatePrivacySettings(_ settings: PrivacySettings) async throws -> PrivacySettings {
        try await currentRepository.updatePrivacySettings(settings)
    }

    func fetchLoginRecords() async throws -> [LoginRecordItem] {
        try await currentRepository.fetchLoginRecords()
    }

    func fetchPhoneAttributions() async throws -> [PhoneAttribution] {
        try await currentRepository.fetchPhoneAttributions()
    }

    func fetchPhoneStatus() async throws -> ContactBindingStatus {
        try await currentRepository.fetchPhoneStatus()
    }

    func sendPhoneVerification(areaCode: Int, phone: String) async throws {
        try await currentRepository.sendPhoneVerification(areaCode: areaCode, phone: phone)
    }

    func bindPhone(request: PhoneBindRequest) async throws -> ContactBindingStatus {
        try await currentRepository.bindPhone(request: request)
    }

    func unbindPhone() async throws -> ContactBindingStatus {
        try await currentRepository.unbindPhone()
    }

    func fetchEmailStatus() async throws -> ContactBindingStatus {
        try await currentRepository.fetchEmailStatus()
    }

    func sendEmailVerification(email: String) async throws {
        try await currentRepository.sendEmailVerification(email: email)
    }

    func bindEmail(email: String, randomCode: String) async throws -> ContactBindingStatus {
        try await currentRepository.bindEmail(email: email, randomCode: randomCode)
    }

    func unbindEmail() async throws -> ContactBindingStatus {
        try await currentRepository.unbindEmail()
    }

    func submitFeedback(_ submission: FeedbackSubmission) async throws {
        try await currentRepository.submitFeedback(submission)
    }

    func fetchDownloadStatus() async throws -> DownloadDataStatus {
        try await currentRepository.fetchDownloadStatus()
    }

    func startDataExport() async throws -> DownloadDataStatus {
        try await currentRepository.startDataExport()
    }

    func fetchDownloadURL() async throws -> DownloadDataStatus {
        try await currentRepository.fetchDownloadURL()
    }

    func fetchAvatarState() async throws -> AvatarState {
        try await currentRepository.fetchAvatarState()
    }

    func uploadAvatar(_ avatar: UploadImageAsset) async throws -> AvatarState {
        try await currentRepository.uploadAvatar(avatar)
    }

    func deleteAvatar() async throws -> AvatarState {
        try await currentRepository.deleteAvatar()
    }

    func deleteAccount(password: String) async throws {
        try await currentRepository.deleteAccount(password: password)
    }

    func fetchCampusCredentialStatus() async throws -> CampusCredentialStatus {
        try await currentRepository.fetchCampusCredentialStatus()
    }

    func recordCampusCredentialConsent(metadata: CampusCredentialConsentMetadata) async throws -> CampusCredentialStatus {
        try await currentRepository.recordCampusCredentialConsent(metadata: metadata)
    }

    func revokeCampusCredentialConsent() async throws -> CampusCredentialStatus {
        try await currentRepository.revokeCampusCredentialConsent()
    }

    func deleteCampusCredential() async throws -> CampusCredentialStatus {
        try await currentRepository.deleteCampusCredential()
    }

    func setQuickAuthEnabled(_ enabled: Bool) async throws -> CampusCredentialStatus {
        try await currentRepository.setQuickAuthEnabled(enabled)
    }

    private var currentRepository: any AccountCenterRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
