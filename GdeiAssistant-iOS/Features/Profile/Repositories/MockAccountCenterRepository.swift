import Foundation

@MainActor
final class MockAccountCenterRepository: AccountCenterRepository {
    private var privacySettings = PrivacySettings.default
    private var phoneStatus = ContactBindingStatus(
        isBound: true,
        rawValue: "13812345678",
        maskedValue: "138****5678",
        note: String(format: localizedString("bindPhone.boundHint"), 86),
        countryCode: 86,
        username: MockSeedData.demoProfile.username
    )
    private var emailStatus = ContactBindingStatus(
        isBound: true,
        rawValue: "student@gdei.edu.cn",
        maskedValue: "stu***@gdei.edu.cn",
        note: localizedString("bindEmail.boundHint"),
        countryCode: nil,
        username: nil
    )
    private var downloadState = DownloadDataStatus(
        state: .idle,
        downloadURL: nil
    )
    private var avatarState = AvatarState(url: MockFactory.makeUserProfile().avatarURL)
    private var campusCredentialStatus = CampusCredentialStatus(
        hasActiveConsent: true,
        hasSavedCredential: true,
        quickAuthEnabled: true,
        consentedAt: "2026-04-25 10:00",
        revokedAt: nil,
        policyDate: nil,
        effectiveDate: nil,
        maskedCampusAccount: SensitiveValueMasker.maskCampusAccount(MockSeedData.demoProfile.username)
    )
    private var records: [LoginRecordItem] = [
        LoginRecordItem(id: "1", timeText: "2026-03-08 09:24", ip: "113.108.18.12", area: "广东 广州", device: "iPhone 15 Pro", statusText: localizedString("loginRecord.success")),
        LoginRecordItem(id: "2", timeText: "2026-03-07 21:16", ip: "113.108.18.15", area: "广东 广州", device: "Web", statusText: localizedString("loginRecord.success")),
        LoginRecordItem(id: "3", timeText: "2026-03-05 08:02", ip: "120.230.17.88", area: "广东 佛山", device: "iPad", statusText: localizedString("loginRecord.success"))
    ]

    func fetchPrivacySettings() async throws -> PrivacySettings {
        try await Task.sleep(nanoseconds: 150_000_000)
        return privacySettings
    }

    func updatePrivacySettings(_ settings: PrivacySettings) async throws -> PrivacySettings {
        try await Task.sleep(nanoseconds: 180_000_000)
        privacySettings = settings
        return settings
    }

    func fetchLoginRecords() async throws -> [LoginRecordItem] {
        try await Task.sleep(nanoseconds: 150_000_000)
        return records
    }

    func fetchPhoneAttributions() async throws -> [PhoneAttribution] {
        [
            PhoneAttribution(id: 86, code: 86, flag: "🇨🇳", name: localizedString("bindPhone.area.mainlandChina")),
            PhoneAttribution(id: 852, code: 852, flag: "🇭🇰", name: localizedString("bindPhone.area.hongKong")),
            PhoneAttribution(id: 853, code: 853, flag: "🇲🇴", name: localizedString("bindPhone.area.macau"))
        ]
    }

    func fetchPhoneStatus() async throws -> ContactBindingStatus {
        phoneStatus
    }

    func sendPhoneVerification(areaCode: Int, phone: String) async throws {
        try await Task.sleep(nanoseconds: 120_000_000)
        guard phone.count >= 7 else {
            throw NetworkError.server(code: 400, message: localizedString("bindPhone.invalidFormat"))
        }
        _ = areaCode
    }

    func bindPhone(request: PhoneBindRequest) async throws -> ContactBindingStatus {
        try await Task.sleep(nanoseconds: 180_000_000)
        guard request.randomCode == "123456" else {
            throw NetworkError.server(code: 400, message: localizedString("bindPhone.invalidCode"))
        }
        phoneStatus = ContactBindingStatus(
            isBound: true,
            rawValue: request.phone,
            maskedValue: "\(request.phone.prefix(3))****\(request.phone.suffix(4))",
            note: String(format: localizedString("bindPhone.boundHint"), request.areaCode),
            countryCode: request.areaCode,
            username: MockSeedData.demoProfile.username
        )
        return phoneStatus
    }

    func unbindPhone() async throws -> ContactBindingStatus {
        try await Task.sleep(nanoseconds: 150_000_000)
        phoneStatus = ContactBindingStatus(
            isBound: false,
            rawValue: nil,
            maskedValue: localizedString("bindPhone.notBound"),
            note: localizedString("bindPhone.notBoundHint"),
            countryCode: nil,
            username: nil
        )
        return phoneStatus
    }

    func fetchEmailStatus() async throws -> ContactBindingStatus {
        emailStatus
    }

    func sendEmailVerification(email: String) async throws {
        try await Task.sleep(nanoseconds: 120_000_000)
        guard email.contains("@") else {
            throw NetworkError.server(code: 400, message: localizedString("bindEmail.invalidFormat"))
        }
    }

    func bindEmail(email: String, randomCode: String) async throws -> ContactBindingStatus {
        try await Task.sleep(nanoseconds: 180_000_000)
        guard randomCode == "123456" else {
            throw NetworkError.server(code: 400, message: localizedString("bindEmail.invalidCode"))
        }
        let masked = AccountCenterRemoteMapper.mapEmailStatus(email).maskedValue
        emailStatus = ContactBindingStatus(
            isBound: true,
            rawValue: email,
            maskedValue: masked,
            note: localizedString("bindEmail.boundHint"),
            countryCode: nil,
            username: nil
        )
        return emailStatus
    }

    func unbindEmail() async throws -> ContactBindingStatus {
        try await Task.sleep(nanoseconds: 150_000_000)
        emailStatus = ContactBindingStatus(
            isBound: false,
            rawValue: nil,
            maskedValue: localizedString("bindEmail.notBound"),
            note: localizedString("bindEmail.notBoundHint"),
            countryCode: nil,
            username: nil
        )
        return emailStatus
    }

    func submitFeedback(_ submission: FeedbackSubmission) async throws {
        try await Task.sleep(nanoseconds: 220_000_000)
        guard FormValidationSupport.hasText(submission.content) else {
            throw NetworkError.server(code: 400, message: localizedString("feedback.contentEmpty"))
        }
    }

    func fetchDownloadStatus() async throws -> DownloadDataStatus {
        downloadState
    }

    func startDataExport() async throws -> DownloadDataStatus {
        try await Task.sleep(nanoseconds: 250_000_000)
        downloadState = DownloadDataStatus(
            state: .exporting,
            downloadURL: nil
        )
        return downloadState
    }

    func fetchDownloadURL() async throws -> DownloadDataStatus {
        try await Task.sleep(nanoseconds: 200_000_000)
        downloadState = DownloadDataStatus(
            state: .exported,
            downloadURL: "https://mock.gdeiassistant.cn/export/userdata-demo.zip"
        )
        return downloadState
    }

    func fetchAvatarState() async throws -> AvatarState {
        avatarState
    }

    func uploadAvatar(_ avatar: UploadImageAsset) async throws -> AvatarState {
        try await Task.sleep(nanoseconds: 220_000_000)
        _ = avatar
        avatarState = AvatarState(url: "https://mock.gdeiassistant.cn/avatar/demo.jpg")
        return avatarState
    }

    func deleteAvatar() async throws -> AvatarState {
        try await Task.sleep(nanoseconds: 180_000_000)
        avatarState = AvatarState(url: nil)
        return avatarState
    }

    func deleteAccount(password: String) async throws {
        try await Task.sleep(nanoseconds: 250_000_000)
        guard password == "123456" else {
            throw NetworkError.server(code: 400, message: localizedString("deleteAccount.passwordInvalid"))
        }
    }

    func fetchCampusCredentialStatus() async throws -> CampusCredentialStatus {
        try await Task.sleep(nanoseconds: 120_000_000)
        return campusCredentialStatus
    }

    func recordCampusCredentialConsent(metadata: CampusCredentialConsentMetadata) async throws -> CampusCredentialStatus {
        try await Task.sleep(nanoseconds: 120_000_000)
        campusCredentialStatus.hasActiveConsent = true
        campusCredentialStatus.revokedAt = nil
        campusCredentialStatus.policyDate = metadata.policyDate ?? campusCredentialStatus.policyDate
        campusCredentialStatus.effectiveDate = metadata.effectiveDate ?? campusCredentialStatus.effectiveDate
        campusCredentialStatus.consentedAt = localizedString("common.justNow")
        return campusCredentialStatus
    }

    func revokeCampusCredentialConsent() async throws -> CampusCredentialStatus {
        try await Task.sleep(nanoseconds: 150_000_000)
        campusCredentialStatus.hasActiveConsent = false
        campusCredentialStatus.quickAuthEnabled = false
        campusCredentialStatus.revokedAt = localizedString("common.justNow")
        return campusCredentialStatus
    }

    func deleteCampusCredential() async throws -> CampusCredentialStatus {
        try await Task.sleep(nanoseconds: 150_000_000)
        campusCredentialStatus.hasActiveConsent = false
        campusCredentialStatus.hasSavedCredential = false
        campusCredentialStatus.quickAuthEnabled = false
        campusCredentialStatus.revokedAt = localizedString("common.justNow")
        campusCredentialStatus.maskedCampusAccount = nil
        return campusCredentialStatus
    }

    func setQuickAuthEnabled(_ enabled: Bool) async throws -> CampusCredentialStatus {
        try await Task.sleep(nanoseconds: 150_000_000)
        if enabled && !campusCredentialStatus.hasActiveConsent {
            throw NetworkError.server(code: 400, message: localizedString("campusCredential.enableNeedConsent"))
        }
        if enabled && !campusCredentialStatus.hasSavedCredential {
            throw NetworkError.server(code: 400, message: localizedString("campusCredential.enableNeedCredential"))
        }
        campusCredentialStatus.quickAuthEnabled = enabled
        return campusCredentialStatus
    }
}
