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
    func testSelectedSystemRegionsFollowAllLocalesWithoutMutatingStoredProfile() throws {
        let location = ProfileLocationSelection(displayName: "中国 广东 广州", regionCode: "CN", stateCode: "44", cityCode: "1")
        let hometown = ProfileLocationSelection(displayName: "中国 广东 汕头", regionCode: "CN", stateCode: "44", cityCode: "5")
        let profile = UserProfile(id: "region-test", username: "demo", nickname: "中國 / Alice", avatarURL: "", college: "计算机科学系", collegeCode: 11, major: "软件工程", majorCode: "software_engineering", grade: "2023", bio: "我寫嘅內容", location: location.displayName, locationSelection: location, hometown: hometown.displayName, hometownSelection: hometown)
        let expected = [
            "zh-CN": ["中国 广东 广州", "中国 广东 汕头"],
            "zh-HK": ["中國 廣東 廣州", "中國 廣東 汕頭"],
            "zh-TW": ["中國 廣東 廣州", "中國 廣東 汕頭"],
            "en": ["Guangzhou, Guangdong, China", "Shantou, Guangdong, China"],
            "ja": ["広州, 広東, 中国", "汕頭, 広東, 中国"],
            "ko": ["광저우, 광둥, 중국", "산터우, 광둥, 중국"]
        ]
        for language in AppLanguage.allCases {
            let locale = language.localeIdentifier
            let names = try XCTUnwrap(expected[locale])
            XCTAssertEqual(profile.locationDisplayName(localeIdentifier: locale), names[0])
            XCTAssertEqual(profile.hometownDisplayName(localeIdentifier: locale), names[1])
            let faculty = LocalizedProfileCatalog.catalog(for: locale).defaultOptions.faculties.first(where: { $0.code == 11 })
            XCTAssertEqual(profile.collegeDisplayName(localeIdentifier: locale), faculty?.label)
            XCTAssertEqual(profile.majorDisplayName(localeIdentifier: locale), faculty?.majors.first(where: { $0.code == "software_engineering" })?.label)
        }
        XCTAssertEqual(profile.locationSelection, location)
        XCTAssertEqual(profile.hometownSelection, hometown)
        XCTAssertEqual(profile.location, "中国 广东 广州")
        XCTAssertEqual(profile.hometown, "中国 广东 汕头")
        XCTAssertEqual(profile.nickname, "中國 / Alice")
        XCTAssertEqual(profile.bio, "我寫嘅內容")
    }

    @MainActor
    func testSparseLocationPickerRelabelsCodesAndKeepsUnknownOptions() throws {
        let options = [ProfileLocationRegion(code: "CN", name: "中国", states: [
            ProfileLocationState(code: "44", name: "广东", cities: [
                ProfileLocationCity(code: "1", name: "广州"), ProfileLocationCity(code: "custom", name: "My custom place")
            ])
        ])]
        for language in AppLanguage.allCases {
            let relabeled = ProfileLocationCatalog.localizing(options, localeIdentifier: language.localeIdentifier)
            let region = try XCTUnwrap(relabeled.first)
            let state = try XCTUnwrap(region.states.first)
            XCTAssertEqual(region.code, "CN")
            XCTAssertEqual(region.states.map(\.code), ["44"])
            XCTAssertEqual(state.cities.map(\.code), ["1", "custom"])
            XCTAssertEqual(state.cities.last?.name, "My custom place")
            let resolved = ProfileLocationCatalog.selection(regionCode: region.code, stateCode: state.code, cityCode: "1", localeIdentifier: language.localeIdentifier)
            XCTAssertEqual(ProfileFormSupport.makeLocationDisplay(region: region.name, state: state.name, city: state.cities[0].name, localeIdentifier: language.localeIdentifier), resolved?.displayName)
        }
        XCTAssertEqual(options.first?.name, "中国")
    }

    @MainActor
    func testKnownLocationLevelsAndUnknownSelectionsStayDistinct() {
        XCTAssertEqual(ProfileLocationCatalog.selection(regionCode: "CN", stateCode: "", cityCode: "", localeIdentifier: "zh-HK")?.displayName, "中國")
        XCTAssertEqual(ProfileLocationCatalog.selection(regionCode: "CN", stateCode: "44", cityCode: "", localeIdentifier: "zh-TW")?.displayName, "中國 廣東")
        XCTAssertNil(ProfileLocationCatalog.selection(regionCode: "CN", stateCode: "", cityCode: "1"))
        XCTAssertNil(ProfileLocationCatalog.selection(regionCode: "CN", stateCode: "invalid", cityCode: ""))
        let unknownCity = ProfileLocationSelection(displayName: "中国 广东 未知城", regionCode: "CN", stateCode: "44", cityCode: "9999")
        XCTAssertNil(ProfileLocationCatalog.selection(regionCode: "CN", stateCode: "44", cityCode: "9999"))
        XCTAssertEqual(ProfileLocationCatalog.displayName(for: unknownCity, fallback: unknownCity.displayName, localeIdentifier: "en"), "中国 广东 未知城", "A known parent must not silently truncate an unknown child code")
        let unknown = ProfileLocationSelection(displayName: "自定義地點", regionCode: "custom", stateCode: "", cityCode: "")
        XCTAssertEqual(ProfileLocationCatalog.displayName(for: unknown, fallback: "自定義地點", localeIdentifier: "en"), "自定義地點")
        XCTAssertEqual(ProfileLocationCatalog.displayName(for: nil, fallback: "中國街 12號", localeIdentifier: "en"), "中國街 12號")
    }

    @MainActor
    func testKnownIPPathsLocalizeExactlyAndKeepAmbiguousAndUnknownText() {
        let expected = [
            "zh-CN": ["广东", "广东 广州"], "zh-HK": ["廣東", "廣東 廣州"],
            "zh-TW": ["廣東", "廣東 廣州"], "en": ["Guangdong", "Guangzhou, Guangdong"],
            "ja": ["広東", "広州, 広東"], "ko": ["광둥", "광저우, 광둥"]
        ]
        for (locale, names) in expected {
            XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("广东", localeIdentifier: locale), names[0])
            XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("廣東", localeIdentifier: locale), names[0])
            XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("广东 广州", localeIdentifier: locale), names[1])
            XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("Guangzhou, Guangdong", localeIdentifier: locale), names[1])
            XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("Guangdong Guangzhou", localeIdentifier: locale), names[1])
            XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("广东广州", localeIdentifier: locale), names[1])
            XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("中國廣東廣州", localeIdentifier: locale), ProfileLocationCatalog.displayName(regionCode: "CN", stateCode: "44", cityCode: "1", localeIdentifier: locale))
            XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("我住在广东 广州", localeIdentifier: locale), "我住在广东 广州")
            XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("Unknown region", localeIdentifier: locale), "Unknown region")
        }
        XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("Shanxi", localeIdentifier: "zh-HK"), "Shanxi", "The alias matches 山西 and 陕西 with different localized names")
        XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("佛山", localeIdentifier: "en"), "Foshan")
        XCTAssertEqual(ProfileLocationCatalog.areaDisplayName("仏山", localeIdentifier: "ko"), "포산")
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
