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
