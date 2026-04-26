import XCTest
@testable import GdeiAssistant_iOS

final class ProfileFormSupportTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.selectedLocale)
        super.tearDown()
    }

    func testProfileSaveResultPreservesDetailedErrorMessage() {
        XCTAssertEqual(
            ProfileSaveResult.from(didSave: false, errorMessage: "Nickname is required"),
            .failure(message: "Nickname is required")
        )
    }

    func testProfileSaveResultFallsBackWhenDetailedErrorMessageIsMissing() {
        XCTAssertEqual(
            ProfileSaveResult.from(didSave: false, errorMessage: nil),
            .failure(message: localizedString("common.saveFailed"))
        )
    }

    func testMajorOptionsFollowSelectedFaculty() {
        XCTAssertEqual(
            ProfileFormSupport.defaultOptions.majorOptions(for: "计算机科学系"),
            [ProfileFormSupport.unselectedOption, "软件工程", "网络工程", "计算机科学与技术", "物联网工程"]
        )
        XCTAssertEqual(ProfileFormSupport.defaultOptions.majorOptions(for: "不存在的院系"), [ProfileFormSupport.unselectedOption])
    }

    func testLocationDisplayDeduplicatesAdjacentSegments() {
        XCTAssertEqual(
            ProfileFormSupport.makeLocationDisplay(region: "中国", state: "广东", city: "广东"),
            "中国 广东"
        )
        XCTAssertEqual(
            ProfileFormSupport.makeLocationDisplay(region: "中国", state: "广东", city: "广州"),
            "中国 广东 广州"
        )
    }

    @MainActor
    func testMockProfileRepositorySharesCanonicalProfileOptions() async throws {
        let repository = MockProfileRepository()

        let options = try await repository.fetchProfileOptions()

        XCTAssertEqual(options.faculties.count, ProfileFormSupport.defaultOptions.faculties.count)
        XCTAssertEqual(options.facultyCode(for: "中文系"), 3)
        XCTAssertEqual(options.marketplaceItemTypes.first?.label, "校园代步")
        XCTAssertEqual(options.lostFoundModes.last?.label, "失物招领")
    }

    func testDefaultProfileOptionsFollowSelectedLocale() {
        UserDefaults.standard.set("en-US", forKey: AppConstants.UserDefaultsKeys.selectedLocale)

        let options = ProfileFormSupport.defaultOptions

        XCTAssertEqual(ProfileFormSupport.unselectedOption, "Not selected")
        XCTAssertEqual(options.faculties.first(where: { $0.code == 11 })?.label, "Department of Computer Science")
        XCTAssertEqual(options.majorOptions(for: "Department of Computer Science"), ["Not selected", "Software Engineering", "Network Engineering", "Computer Science and Technology", "Internet of Things Engineering"])
    }

    func testMockProfileUsesLocalizedLabelsAndLocation() {
        UserDefaults.standard.set("ja-JP", forKey: AppConstants.UserDefaultsKeys.selectedLocale)

        let profile = MockSeedData.demoProfile

        XCTAssertEqual(profile.college, "計算機科学科")
        XCTAssertEqual(profile.major, "ソフトウェア工学")
        XCTAssertEqual(profile.location, "中国 広東省 広州市")
        XCTAssertEqual(profile.hometown, "中国 広東省 汕頭市")
        XCTAssertEqual(profile.ipArea, "広東")
    }

    @MainActor
    func testBindPhoneLoadExpandsSparseRepositoryAttributionsWithBundledCatalog() async {
        let repository = RecordingAccountCenterRepository()
        repository.phoneAttributions = [
            PhoneAttribution(id: 86, code: 86, flag: "🇨🇳", name: "China")
        ]
        let viewModel = BindPhoneViewModel(repository: repository)

        await viewModel.load()

        XCTAssertGreaterThan(viewModel.attributions.count, 150)
        XCTAssertTrue(viewModel.attributions.contains(where: { $0.code == 1 }))
        XCTAssertTrue(viewModel.attributions.contains(where: { $0.code == 44 }))
        XCTAssertTrue(viewModel.attributions.contains(where: { $0.code == 81 }))
        XCTAssertTrue(viewModel.attributions.contains(where: { $0.code == 852 }))
        XCTAssertTrue(viewModel.attributions.contains(where: { $0.code == 886 }))
    }

}

@MainActor
private final class RecordingAccountCenterRepository: AccountCenterRepository {
    var phoneAttributions: [PhoneAttribution] = [
        PhoneAttribution(id: 86, code: 86, flag: "🇨🇳", name: "China")
    ]
    var phoneStatus = ContactBindingStatus(
        isBound: false,
        rawValue: nil,
        maskedValue: localizedString("bindPhone.notBound"),
        note: localizedString("bindPhone.notBoundHint"),
        countryCode: nil,
        username: nil
    )
    func fetchPrivacySettings() async throws -> PrivacySettings { .default }
    func updatePrivacySettings(_ settings: PrivacySettings) async throws -> PrivacySettings { settings }
    func fetchLoginRecords() async throws -> [LoginRecordItem] { [] }
    func fetchPhoneAttributions() async throws -> [PhoneAttribution] { phoneAttributions }
    func fetchPhoneStatus() async throws -> ContactBindingStatus { phoneStatus }
    func sendPhoneVerification(areaCode: Int, phone: String) async throws {}

    func bindPhone(request: PhoneBindRequest) async throws -> ContactBindingStatus {
        phoneStatus = ContactBindingStatus(
            isBound: true,
            rawValue: request.phone,
            maskedValue: request.phone,
            note: localizedString("bindPhone.boundHintWithoutAreaCode"),
            countryCode: request.areaCode,
            username: nil
        )
        return phoneStatus
    }

    func unbindPhone() async throws -> ContactBindingStatus {
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

    func fetchEmailStatus() async throws -> ContactBindingStatus { phoneStatus }
    func sendEmailVerification(email: String) async throws {}
    func bindEmail(email: String, randomCode: String) async throws -> ContactBindingStatus { phoneStatus }
    func unbindEmail() async throws -> ContactBindingStatus { phoneStatus }
    func submitFeedback(_ submission: FeedbackSubmission) async throws {}
    func fetchDownloadStatus() async throws -> DownloadDataStatus { DownloadDataStatus(state: .idle, downloadURL: nil) }
    func startDataExport() async throws -> DownloadDataStatus { DownloadDataStatus(state: .idle, downloadURL: nil) }
    func fetchDownloadURL() async throws -> DownloadDataStatus { DownloadDataStatus(state: .idle, downloadURL: nil) }
    func fetchAvatarState() async throws -> AvatarState { AvatarState(url: nil) }
    func uploadAvatar(_ avatar: UploadImageAsset) async throws -> AvatarState { AvatarState(url: nil) }
    func deleteAvatar() async throws -> AvatarState { AvatarState(url: nil) }
    func deleteAccount(password: String) async throws {}
    func fetchCampusCredentialStatus() async throws -> CampusCredentialStatus { .empty }
    func recordCampusCredentialConsent(metadata: CampusCredentialConsentMetadata) async throws -> CampusCredentialStatus { .empty }
    func revokeCampusCredentialConsent() async throws -> CampusCredentialStatus { .empty }
    func deleteCampusCredential() async throws -> CampusCredentialStatus { .empty }
    func setQuickAuthEnabled(_ enabled: Bool) async throws -> CampusCredentialStatus { .empty }
}
