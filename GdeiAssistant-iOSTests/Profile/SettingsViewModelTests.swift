import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testUpdateNetworkEnvironmentPersistsPreferenceAndUpdatesBaseURLInDebug() {
        let defaults = makeDefaults(testName: #function)
        let preferences = UserPreferences(defaults: defaults)
        let environment = AppEnvironment(
            networkEnvironment: .staging,
            dataSourceMode: .remote,
            isDebug: true,
            clientType: "IOS"
        )
        let viewModel = SettingsViewModel(environment: environment, preferences: preferences)
        TestLifetimeRetainer.retain(viewModel)

        viewModel.updateNetworkEnvironment(.dev)

        XCTAssertEqual(environment.networkEnvironment, .dev)
        XCTAssertEqual(environment.baseURL, NetworkEnvironment.dev.baseURL)
        XCTAssertEqual(preferences.currentNetworkEnvironment, .dev)
        XCTAssertTrue(viewModel.showReloadHint)
    }

    func testUpdateNetworkEnvironmentIsIgnoredOutsideDebugBuilds() {
        let defaults = makeDefaults(testName: #function)
        let preferences = UserPreferences(defaults: defaults)
        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: false,
            clientType: "IOS"
        )
        let viewModel = SettingsViewModel(environment: environment, preferences: preferences)
        TestLifetimeRetainer.retain(viewModel)

        viewModel.updateNetworkEnvironment(.dev)

        XCTAssertEqual(environment.networkEnvironment, .prod)
        XCTAssertEqual(environment.baseURL, NetworkEnvironment.prod.baseURL)
        XCTAssertEqual(preferences.currentNetworkEnvironment, .prod)
        XCTAssertFalse(viewModel.showReloadHint)
    }

    func testUpdateMockEnabledSwitchesEnvironmentModeInDebug() {
        let defaults = makeDefaults(testName: #function)
        let preferences = UserPreferences(defaults: defaults)
        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: true,
            clientType: "IOS"
        )
        let viewModel = SettingsViewModel(environment: environment, preferences: preferences)
        TestLifetimeRetainer.retain(viewModel)

        viewModel.updateMockEnabled(true)

        XCTAssertEqual(environment.dataSourceMode, .mock)
        XCTAssertEqual(preferences.currentDataSourceMode, .mock)
        XCTAssertTrue(viewModel.showReloadHint)
    }

    private func makeDefaults(testName: String) -> UserDefaults {
        let suiteName = "SettingsViewModelTests.\(testName)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

@MainActor
final class RemoteCampusCredentialRepositoryTests: XCTestCase {
    private var repository: RemoteAccountCenterRepository!

    override func setUp() async throws {
        CampusCredentialURLProtocol.requests = []
        CampusCredentialURLProtocol.responseStub = { request in
            let path = request.url?.path ?? ""
            let data: String
            if path.contains("quick-auth") {
                data = #"{"code":200,"success":true,"message":"","data":{"hasActiveConsent":true,"hasSavedCredential":true,"quickAuthEnabled":true,"maskedCampusAccount":"2023001234"}}"#
            } else {
                data = #"{"code":200,"success":true,"message":"","data":{"hasActiveConsent":true,"hasSavedCredential":true,"quickAuthEnabled":false,"consentedAt":"2026-04-25 10:00","policyDate":"2026-04-25","effectiveDate":"2026-05-11","maskedCampusAccount":"2023001234","password":"should-not-be-used"}}"#
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(data.utf8))
        }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [CampusCredentialURLProtocol.self]
        let session = URLSession(configuration: config)
        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: false,
            clientType: "IOS"
        )
        environment.baseURL = URL(string: "https://test.example.com/api")!
        let apiClient = APIClient(
            environment: environment,
            session: session,
            tokenProvider: { "token-123" },
            onUnauthorized: {}
        )
        repository = RemoteAccountCenterRepository(apiClient: apiClient)
    }

    override func tearDown() async throws {
        CampusCredentialURLProtocol.requests = []
        CampusCredentialURLProtocol.responseStub = nil
        repository = nil
    }

    func testFetchCampusCredentialStatusDecodesSafeFieldsAndMasksAccount() async throws {
        let status = try await repository.fetchCampusCredentialStatus()

        XCTAssertTrue(status.hasActiveConsent)
        XCTAssertTrue(status.hasSavedCredential)
        XCTAssertFalse(status.quickAuthEnabled)
        XCTAssertEqual(status.consentedAt, "2026-04-25 10:00")
        XCTAssertEqual(status.policyDate, "2026-04-25")
        XCTAssertEqual(status.effectiveDate, "2026-05-11")
        XCTAssertEqual(status.maskedCampusAccount, "20****34")
        XCTAssertEqual(CampusCredentialURLProtocol.requests.first?.path, "/api/campus-credential/status")
    }

    func testCampusCredentialActionsUseExpectedMethodsAndBodies() async throws {
        _ = try await repository.recordCampusCredentialConsent(
            metadata: CampusCredentialConsentMetadata(scene: CampusCredentialDefaults.settingsScene)
        )
        _ = try await repository.revokeCampusCredentialConsent()
        _ = try await repository.deleteCampusCredential()
        _ = try await repository.setQuickAuthEnabled(true)

        let requests = CampusCredentialURLProtocol.requests
        XCTAssertEqual(requests.map(\.method), ["POST", "POST", "DELETE", "POST"])
        XCTAssertEqual(requests.map(\.path), [
            "/api/campus-credential/consent",
            "/api/campus-credential/revoke",
            "/api/campus-credential",
            "/api/campus-credential/quick-auth"
        ])

        let consentBody = requests[0].body
        XCTAssertTrue(consentBody.contains(#""scene":"SETTINGS""#))
        XCTAssertFalse(consentBody.contains("policyDate"))
        XCTAssertFalse(consentBody.contains("effectiveDate"))
        XCTAssertFalse(consentBody.contains("password"))

        let quickAuthBody = requests[3].body
        XCTAssertTrue(quickAuthBody.contains(#""enabled":true"#))
    }
}

@MainActor
final class CampusCredentialViewModelTests: XCTestCase {
    func testLoadStatusUpdatesCampusCredentialState() async {
        let repository = CampusCredentialAccountRepositorySpy()
        repository.status = CampusCredentialStatus(
            hasActiveConsent: true,
            hasSavedCredential: true,
            quickAuthEnabled: true,
            consentedAt: "2026-04-25",
            revokedAt: nil,
            policyDate: "2026-04-25",
            effectiveDate: "2026-05-11",
            maskedCampusAccount: "20****34"
        )
        let viewModel = CampusCredentialViewModel(repository: repository)
        TestLifetimeRetainer.retain(viewModel)

        await viewModel.load()

        XCTAssertEqual(viewModel.status, repository.status)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadSkipsWhileCredentialActionIsRunning() async {
        let repository = CampusCredentialAccountRepositorySpy()
        repository.status.hasActiveConsent = true
        let viewModel = CampusCredentialViewModel(repository: repository)
        viewModel.isActionRunning = true
        TestLifetimeRetainer.retain(viewModel)

        await viewModel.load()

        XCTAssertEqual(repository.fetchCampusCredentialStatusCallCount, 0)
        XCTAssertEqual(viewModel.status, .empty)
    }

    func testRevokeConsentSuccessUpdatesStatusAndMessage() async {
        let repository = CampusCredentialAccountRepositorySpy()
        repository.status.hasActiveConsent = true
        repository.status.quickAuthEnabled = true
        let viewModel = CampusCredentialViewModel(repository: repository)
        TestLifetimeRetainer.retain(viewModel)

        await viewModel.revokeConsent()

        XCTAssertFalse(viewModel.status.hasActiveConsent)
        XCTAssertFalse(viewModel.status.quickAuthEnabled)
        XCTAssertEqual(viewModel.noticeMessage, localizedString("campusCredential.revokeSuccess"))
    }

    func testRecordConsentUsesCurrentServerPolicyDatesWhenAvailable() async {
        let repository = CampusCredentialAccountRepositorySpy()
        repository.status.hasActiveConsent = false
        repository.status.policyDate = "2026-06-01"
        repository.status.effectiveDate = "2026-06-15"
        let viewModel = CampusCredentialViewModel(repository: repository)
        viewModel.status = repository.status
        TestLifetimeRetainer.retain(viewModel)

        await viewModel.recordConsent()

        XCTAssertEqual(repository.recordedConsentMetadata?.scene, CampusCredentialDefaults.settingsScene)
        XCTAssertEqual(repository.recordedConsentMetadata?.policyDate, "2026-06-01")
        XCTAssertEqual(repository.recordedConsentMetadata?.effectiveDate, "2026-06-15")
        XCTAssertTrue(viewModel.status.hasActiveConsent)
        XCTAssertEqual(viewModel.noticeMessage, localizedString("campusCredential.reauthorizeSuccess"))
    }

    func testDeleteCredentialSuccessUpdatesStatusAndMessage() async {
        let repository = CampusCredentialAccountRepositorySpy()
        repository.status.hasActiveConsent = true
        repository.status.hasSavedCredential = true
        repository.status.quickAuthEnabled = true
        repository.status.maskedCampusAccount = "20****34"
        let viewModel = CampusCredentialViewModel(repository: repository)
        TestLifetimeRetainer.retain(viewModel)

        await viewModel.deleteCredential()

        XCTAssertFalse(viewModel.status.hasSavedCredential)
        XCTAssertNil(viewModel.status.maskedCampusAccount)
        XCTAssertEqual(viewModel.noticeMessage, localizedString("campusCredential.deleteSuccess"))
    }

    func testQuickAuthEnableFailureShowsBackendReason() async {
        let repository = CampusCredentialAccountRepositorySpy()
        repository.quickAuthError = NetworkError.server(code: 400, message: "No saved campus credential")
        let viewModel = CampusCredentialViewModel(repository: repository)
        TestLifetimeRetainer.retain(viewModel)

        await viewModel.setQuickAuthEnabled(true)

        XCTAssertEqual(viewModel.errorMessage, "No saved campus credential")
        XCTAssertEqual(viewModel.noticeMessage, "No saved campus credential")
        XCTAssertFalse(viewModel.status.quickAuthEnabled)
    }
}

final class SensitiveValueMaskerTests: XCTestCase {
    func testMasksPhoneEmailCampusAccountAndTokenLikeValues() {
        XCTAssertEqual(SensitiveValueMasker.maskPhone("13812345678"), "138****5678")
        XCTAssertEqual(SensitiveValueMasker.maskEmail("student@gdei.edu.cn"), "stu***@gdei.edu.cn")
        XCTAssertEqual(SensitiveValueMasker.maskCampusAccount("2023001234"), "20****34")
        XCTAssertEqual(SensitiveValueMasker.maskTokenOrSession("abcd12345678efgh"), "abcd****efgh")
    }

    func testMaskingHandlesEmptyShortAndAlreadyMaskedValues() {
        XCTAssertEqual(SensitiveValueMasker.maskPhone(nil), "")
        XCTAssertEqual(SensitiveValueMasker.maskCampusAccount(""), "")
        XCTAssertEqual(SensitiveValueMasker.maskCampusAccount("7"), "*")
        XCTAssertEqual(SensitiveValueMasker.maskTokenOrSession("abc"), "***")
        XCTAssertEqual(SensitiveValueMasker.maskCampusAccount("20****34"), "20****34")
    }
}

private struct CampusCredentialCapturedRequest {
    let method: String
    let path: String
    let body: String
}

private final class CampusCredentialURLProtocol: URLProtocol {
    static var requests: [CampusCredentialCapturedRequest] = []
    static var responseStub: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(
            CampusCredentialCapturedRequest(
                method: request.httpMethod ?? "",
                path: request.url?.path ?? "",
                body: Self.bodyString(from: request)
            )
        )
        guard let responseStub = Self.responseStub else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        let (response, data) = responseStub(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func bodyString(from request: URLRequest) -> String {
        if let httpBody = request.httpBody {
            return String(data: httpBody, encoding: .utf8) ?? ""
        }
        guard let stream = request.httpBodyStream else { return "" }

        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: bufferSize)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }

        return String(data: data, encoding: .utf8) ?? ""
    }
}

@MainActor
private final class CampusCredentialAccountRepositorySpy: AccountCenterRepository {
    var status = CampusCredentialStatus.empty
    var quickAuthError: Error?
    var recordedConsentMetadata: CampusCredentialConsentMetadata?
    var fetchCampusCredentialStatusCallCount = 0

    func fetchPrivacySettings() async throws -> PrivacySettings { .default }
    func updatePrivacySettings(_ settings: PrivacySettings) async throws -> PrivacySettings { settings }
    func fetchLoginRecords() async throws -> [LoginRecordItem] { [] }
    func fetchPhoneAttributions() async throws -> [PhoneAttribution] { [] }
    func fetchPhoneStatus() async throws -> ContactBindingStatus {
        ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: "", note: "", countryCode: nil, username: nil)
    }
    func sendPhoneVerification(areaCode: Int, phone: String) async throws {}
    func bindPhone(request: PhoneBindRequest) async throws -> ContactBindingStatus {
        ContactBindingStatus(isBound: true, rawValue: request.phone, maskedValue: request.phone, note: "", countryCode: nil, username: nil)
    }
    func unbindPhone() async throws -> ContactBindingStatus {
        ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: "", note: "", countryCode: nil, username: nil)
    }
    func fetchEmailStatus() async throws -> ContactBindingStatus {
        ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: "", note: "", countryCode: nil, username: nil)
    }
    func sendEmailVerification(email: String) async throws {}
    func bindEmail(email: String, randomCode: String) async throws -> ContactBindingStatus {
        ContactBindingStatus(isBound: true, rawValue: email, maskedValue: email, note: "", countryCode: nil, username: nil)
    }
    func unbindEmail() async throws -> ContactBindingStatus {
        ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: "", note: "", countryCode: nil, username: nil)
    }
    func submitFeedback(_ submission: FeedbackSubmission) async throws {}
    func fetchDownloadStatus() async throws -> DownloadDataStatus { DownloadDataStatus(state: .idle, downloadURL: nil) }
    func startDataExport() async throws -> DownloadDataStatus { DownloadDataStatus(state: .idle, downloadURL: nil) }
    func fetchDownloadURL() async throws -> DownloadDataStatus { DownloadDataStatus(state: .idle, downloadURL: nil) }
    func fetchAvatarState() async throws -> AvatarState { AvatarState(url: nil) }
    func uploadAvatar(_ avatar: UploadImageAsset) async throws -> AvatarState { AvatarState(url: nil) }
    func deleteAvatar() async throws -> AvatarState { AvatarState(url: nil) }
    func deleteAccount(password: String) async throws {}

    func fetchCampusCredentialStatus() async throws -> CampusCredentialStatus {
        fetchCampusCredentialStatusCallCount += 1
        return status
    }

    func recordCampusCredentialConsent(metadata: CampusCredentialConsentMetadata) async throws -> CampusCredentialStatus {
        recordedConsentMetadata = metadata
        status.hasActiveConsent = true
        status.policyDate = metadata.policyDate ?? status.policyDate
        status.effectiveDate = metadata.effectiveDate ?? status.effectiveDate
        return status
    }

    func revokeCampusCredentialConsent() async throws -> CampusCredentialStatus {
        status.hasActiveConsent = false
        status.quickAuthEnabled = false
        return status
    }

    func deleteCampusCredential() async throws -> CampusCredentialStatus {
        status.hasActiveConsent = false
        status.hasSavedCredential = false
        status.quickAuthEnabled = false
        status.maskedCampusAccount = nil
        return status
    }

    func setQuickAuthEnabled(_ enabled: Bool) async throws -> CampusCredentialStatus {
        if let quickAuthError {
            throw quickAuthError
        }
        status.quickAuthEnabled = enabled
        return status
    }
}
