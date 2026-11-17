import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func testMapProfileReadsStructuredFieldsFromRemoteDTO() {
        let dto = UserProfileDTO(
            username: "demo",
            nickname: "Demo",
            avatar: "https://example.com/avatar.png",
            facultyCode: 11,
            majorCode: "software_engineering",
            enrollment: "2023",
            location: ProfileRemoteLocationValueDTO(regionCode: "CN", stateCode: "44", cityCode: "1"),
            hometown: ProfileRemoteLocationValueDTO(regionCode: "CN", stateCode: "44", cityCode: "5"),
            introduction: "bio",
            birthday: "2001-02-03",
            ipArea: "广东省",
            age: 23
        )

        let profile = ProfileRemoteMapper.mapProfile(dto)

        XCTAssertEqual(profile.collegeCode, 11)
        XCTAssertEqual(profile.college, "计算机科学系")
        XCTAssertEqual(profile.majorCode, "software_engineering")
        XCTAssertEqual(profile.major, "软件工程")
        XCTAssertEqual(profile.location, "中国 广东 广州")
        XCTAssertEqual(profile.locationSelection?.regionCode, "CN")
        XCTAssertEqual(profile.locationSelection?.cityCode, "1")
        XCTAssertEqual(profile.hometownSelection?.cityCode, "5")
        let countryOnly = ProfileRemoteMapper.mapProfile(UserProfileDTO(
            username: "demo", nickname: "Demo", avatar: nil, facultyCode: nil, majorCode: nil, enrollment: nil,
            location: ProfileRemoteLocationValueDTO(regionCode: "CN", stateCode: nil, cityCode: nil),
            hometown: ProfileRemoteLocationValueDTO(regionCode: "CN", stateCode: "44", cityCode: nil),
            introduction: nil, birthday: nil, ipArea: nil, age: nil
        ))
        XCTAssertEqual(countryOnly.locationSelection?.regionCode, "CN")
        XCTAssertEqual(countryOnly.locationSelection?.stateCode, "")
        XCTAssertEqual(countryOnly.hometownSelection?.stateCode, "44")
        XCTAssertEqual(countryOnly.hometownSelection?.cityCode, "")
    }

    func testLocaleRelabelingKeepsProfileDraftAndSubmissionCodes() async throws {
        let defaults = UserDefaults.standard
        let key = AppConstants.UserDefaultsKeys.selectedLocale
        let previous = defaults.object(forKey: key)
        defer {
            if let previous { defaults.set(previous, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }
        defaults.set("zh-CN", forKey: key)
        let location = try XCTUnwrap(ProfileLocationCatalog.selection(regionCode: "CN", stateCode: "44", cityCode: "1"))
        let hometown = try XCTUnwrap(ProfileLocationCatalog.selection(regionCode: "CN", stateCode: "44", cityCode: "5"))
        let repository = RecordingProfileRepository()
        repository.profile = UserProfile(id: "profile-locale-test", username: "demo", nickname: "Alice / 中國", avatarURL: "", college: "计算机科学系", collegeCode: 11, major: "软件工程", majorCode: "software_engineering", grade: "2023", bio: "我寫嘅內容", location: location.displayName, locationSelection: location, hometown: hometown.displayName, hometownSelection: hometown)
        let viewModel = ProfileViewModel(repository: repository, sessionState: SessionState())
        await viewModel.loadProfile()
        XCTAssertEqual(viewModel.facultyCode, 11)
        XCTAssertEqual(viewModel.majorCode, "software_engineering")
        XCTAssertEqual(viewModel.enrollment, 2023)
        for language in AppLanguage.allCases {
            let locale = language.localeIdentifier
            let faculty = try XCTUnwrap(LocalizedProfileCatalog.catalog(for: locale).defaultOptions.faculties.first(where: { $0.code == 11 }))
            XCTAssertEqual(viewModel.facultyDisplayName(for: viewModel.facultyCode, localeIdentifier: locale), faculty.label)
            XCTAssertEqual(viewModel.majorDisplayName(for: viewModel.majorCode ?? "", localeIdentifier: locale), faculty.majors.first(where: { $0.code == "software_engineering" })?.label)
        }
        defaults.set("en", forKey: key)
        XCTAssertEqual(viewModel.profileOptions.faculties.first(where: { $0.code == 11 })?.label, "计算机科学系", "The options intentionally remain cached from before the switch")
        let didSave = await viewModel.saveProfile()
        XCTAssertTrue(didSave)
        let request = try XCTUnwrap(repository.updateRequests.last)
        XCTAssertEqual(request.location, location)
        XCTAssertEqual(request.hometown, hometown)
        XCTAssertEqual(request.nickname, "Alice / 中國")
        XCTAssertEqual(request.bio, "我寫嘅內容")
        XCTAssertEqual(request.facultyCode, 11)
        XCTAssertEqual(request.majorCode, "software_engineering")
        XCTAssertEqual(request.enrollment, 2023)
        let patchDTO = try ProfileRemoteMapper.makePatchDTO(from: request)
        XCTAssertEqual(patchDTO.faculty, 11)
        XCTAssertEqual(patchDTO.major, "software_engineering")
        XCTAssertEqual(patchDTO.enrollment, 2023)
        XCTAssertEqual(patchDTO.location?.region, "CN")
        XCTAssertEqual(patchDTO.location?.state, "44")
        XCTAssertEqual(patchDTO.location?.city, "1")
        XCTAssertEqual(patchDTO.hometown?.city, "5")
        await viewModel.loadProfileOptions()
        XCTAssertEqual(viewModel.facultyDisplayName(for: viewModel.facultyCode, localeIdentifier: "en"), "Department of Computer Science")
        XCTAssertEqual(viewModel.majorDisplayName(for: viewModel.majorCode ?? "", localeIdentifier: "en"), "Software Engineering")
    }

    func testMakePatchDTOEncodesExplicitNullsWhenClearingOptionalFields() throws {
        let request = ProfileUpdateRequest(
            nickname: "Demo",
            facultyCode: 0,
            majorCode: "unselected",
            enrollment: nil,
            bio: "",
            birthday: "",
            location: nil,
            hometown: nil
        )
        let dto = try ProfileRemoteMapper.makePatchDTO(from: request)
        let data = try JSONEncoder().encode(dto)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["nickname"] as? String, "Demo")
        XCTAssertEqual(object["faculty"] as? Int, 0)
        XCTAssertEqual(object["introduction"] as? String, "")
        XCTAssertTrue(object["major"] is NSNull)
        XCTAssertTrue(object["enrollment"] is NSNull)
        XCTAssertTrue(object["birthday"] is NSNull)
        XCTAssertTrue(object["location"] is NSNull)
        XCTAssertTrue(object["hometown"] is NSNull)
    }

    func testMapProfileOptionsReadsStructuredMajorOptions() {
        let options = ProfileRemoteMapper.mapProfileOptions(
            ProfileOptionsDTO(
                faculties: [
                    ProfileFacultyOptionDTO(
                        code: 11,
                        majors: ["software_engineering"]
                    )
                ],
                marketplaceItemTypes: [0, 11],
                lostFoundItemTypes: [0, 11],
                lostFoundModes: [0, 1]
            )
        )

        XCTAssertEqual(options.faculties.first?.label, "计算机科学系")
        XCTAssertEqual(options.faculties.first?.majors.first?.code, "software_engineering")
        XCTAssertEqual(options.faculties.first?.majors.first?.label, "软件工程")
        XCTAssertEqual(options.majorCode(for: "计算机科学系", majorLabel: "软件工程"), "software_engineering")
        XCTAssertEqual(options.majorLabel(for: "计算机科学系", majorCode: "software_engineering"), "软件工程")
        XCTAssertEqual(options.marketplaceItemTypes.last?.label, "其他")
        XCTAssertEqual(options.lostFoundModes.first?.label, "寻物启事")
    }

    func testMapLocationRegionsLocalizesCodeOnlyTreeFromCatalog() {
        let regions = ProfileRemoteMapper.mapLocationRegions([
            ProfileLocationRegionDTO(
                code: "CN",
                children: [
                    ProfileLocationStateDTO(
                        code: "44",
                        children: [
                            ProfileLocationCityDTO(code: "1")
                        ]
                    )
                ]
            )
        ])

        XCTAssertEqual(regions.first?.name, "中国")
        XCTAssertEqual(regions.first?.states.first?.name, "广东")
        XCTAssertEqual(regions.first?.states.first?.cities.first?.name, "广州")
    }

    func testClearingBirthdayDoesNotRestoreExistingPickerDateWhenSaving() async {
        let repository = RecordingProfileRepository()
        let sessionState = SessionState()
        let viewModel = ProfileViewModel(repository: repository, sessionState: sessionState)

        await viewModel.loadProfile()
        let existingPickerDate = viewModel.birthdayDate

        viewModel.applyBirthdayEditorChange(
            selectedDate: existingPickerDate,
            hadExistingBirthday: true,
            didChangeSelection: false,
            didRequestClear: true
        )

        let didSave = await viewModel.saveProfile()

        XCTAssertTrue(didSave)
        XCTAssertEqual(repository.updateRequests.last?.birthday, "")
    }

    func testSavingWithoutExistingBirthdayKeepsBirthdayEmptyUntilSelectionChanges() async {
        let repository = RecordingProfileRepository()
        repository.profile = UserProfile(
            id: "user-1",
            username: "demo",
            nickname: "Demo",
            avatarURL: "",
            college: "计算机科学系",
            major: "软件工程",
            grade: "2023级",
            bio: "bio",
            birthday: ""
        )
        let sessionState = SessionState()
        let viewModel = ProfileViewModel(repository: repository, sessionState: sessionState)

        await viewModel.loadProfile()

        viewModel.applyBirthdayEditorChange(
            selectedDate: Date(timeIntervalSince1970: 1_710_000_000),
            hadExistingBirthday: false,
            didChangeSelection: false,
            didRequestClear: false
        )

        let didSave = await viewModel.saveProfile()

        XCTAssertTrue(didSave)
        XCTAssertEqual(repository.updateRequests.last?.birthday, "")
    }

    func testSaveProfileBlocksConcurrentRequestsWhileSaving() async {
        let repository = SuspendingProfileRepository()
        let sessionState = SessionState()
        let viewModel = ProfileViewModel(repository: repository, sessionState: sessionState)
        let firstSaveStarted = expectation(description: "first save started")

        repository.onUpdateStarted = {
            firstSaveStarted.fulfill()
        }

        await viewModel.loadProfile()

        let firstSaveTask = Task {
            await viewModel.saveProfile()
        }

        await fulfillment(of: [firstSaveStarted], timeout: 1.0)

        let secondSaveResult = await viewModel.saveProfile()

        XCTAssertFalse(secondSaveResult)
        XCTAssertEqual(repository.updateCallCount, 1)

        repository.resumeUpdate()

        let firstSaveResult = await firstSaveTask.value

        XCTAssertTrue(firstSaveResult)
        XCTAssertEqual(repository.updateCallCount, 1)
    }

    func testSaveProfileRestoresPersistedDraftWhenRequestFails() async {
        let repository = RecordingProfileRepository()
        repository.updateError = URLError(.notConnectedToInternet)
        let sessionState = SessionState()
        let viewModel = ProfileViewModel(repository: repository, sessionState: sessionState)

        await viewModel.loadProfile()
        viewModel.nickname = "Edited nickname"
        viewModel.bio = "Edited bio"

        let didSave = await viewModel.saveProfile()

        XCTAssertFalse(didSave)
        XCTAssertEqual(viewModel.nickname, repository.profile.nickname)
        XCTAssertEqual(viewModel.bio, repository.profile.bio)
    }

    func testEmptyGradeTreatsUnselectedEnrollmentOptionAsCurrentSelection() async {
        let repository = RecordingProfileRepository()
        repository.profile = UserProfile(
            id: "user-1",
            username: "demo",
            nickname: "Demo",
            avatarURL: "",
            college: "计算机科学系",
            major: "软件工程",
            grade: "",
            bio: "bio",
            birthday: "2001-02-03"
        )
        let sessionState = SessionState()
        let viewModel = ProfileViewModel(repository: repository, sessionState: sessionState)

        await viewModel.loadProfile()

        XCTAssertTrue(viewModel.isEnrollmentOptionSelected(nil))
    }

    func testLoadProfileRestoresStructuredLocationSelectionAndMajorCode() async {
        let repository = RecordingProfileRepository()
        repository.profile = UserProfile(
            id: "user-1",
            username: "demo",
            nickname: "Demo",
            avatarURL: "",
            college: "计算机科学系",
            collegeCode: 11,
            major: "",
            majorCode: "software_engineering",
            grade: "2023级",
            bio: "bio",
            birthday: "2001-02-03",
            location: "中国 广东 广州",
            locationSelection: ProfileLocationSelection(displayName: "中国 广东 广州", regionCode: "CN", stateCode: "44", cityCode: "1"),
            hometown: "中国 广东 汕头",
            hometownSelection: ProfileLocationSelection(displayName: "中国 广东 汕头", regionCode: "CN", stateCode: "44", cityCode: "5")
        )
        let sessionState = SessionState()
        let viewModel = ProfileViewModel(repository: repository, sessionState: sessionState)

        await viewModel.loadProfileOptions()
        await viewModel.loadProfile()

        XCTAssertEqual(viewModel.facultyCode, 11)
        XCTAssertEqual(viewModel.majorCode, "software_engineering")
        XCTAssertEqual(viewModel.enrollment, 2023)
        XCTAssertEqual(viewModel.location, "中国 广东 广州")
        let saved = await viewModel.saveProfile()
        XCTAssertTrue(saved)
        XCTAssertEqual(repository.updateRequests.last?.location?.cityCode, "1")
        XCTAssertEqual(repository.updateRequests.last?.hometown?.cityCode, "5")
    }

    func testMockProfileRepositoryPersistsStructuredProfileValuesOnUpdate() async throws {
        let repository = MockProfileRepository()

        _ = try await repository.fetchProfileOptions()

        let updatedProfile = try await repository.updateProfile(
            request: ProfileUpdateRequest(
                nickname: "新昵称",
                facultyCode: 11,
                majorCode: "software_engineering",
                enrollment: 2024,
                bio: "新的简介",
                birthday: "2002-03-04",
                location: ProfileLocationSelection(
                    displayName: "中国 广东省 广州市",
                    regionCode: "CN",
                    stateCode: "44",
                    cityCode: "1"
                ),
                hometown: ProfileLocationSelection(
                    displayName: "中国 广东省 汕头市",
                    regionCode: "CN",
                    stateCode: "44",
                    cityCode: "5"
                )
            )
        )

        XCTAssertEqual(updatedProfile.collegeCode, 11)
        XCTAssertEqual(updatedProfile.majorCode, "software_engineering")
        XCTAssertEqual(updatedProfile.grade, "2024")
        XCTAssertEqual(updatedProfile.locationSelection?.cityCode, "1")
        XCTAssertEqual(updatedProfile.hometownSelection?.cityCode, "5")
    }

    func testRemoteProfileRepositorySendsSingleAtomicProfilePatch() async throws {
        ProfilePatchURLProtocol.requests = []
        ProfilePatchURLProtocol.responseStub = { request in
            let path = request.url?.path ?? ""
            let body: String
            if path.hasSuffix("/user/profile") {
                body = #"{"code":200,"success":true,"message":"","data":{"username":"demo","nickname":"新昵称","facultyCode":11,"majorCode":null,"enrollment":null,"introduction":"","birthday":null,"location":null,"hometown":null}}"#
            } else {
                body = #"{"code":200,"success":true,"message":"","data":null}"#
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }
        defer {
            ProfilePatchURLProtocol.requests = []
            ProfilePatchURLProtocol.responseStub = nil
        }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ProfilePatchURLProtocol.self]
        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: false,
            clientType: "IOS"
        )
        environment.baseURL = URL(string: "https://test.example.com/api")!
        let apiClient = APIClient(
            environment: environment,
            session: URLSession(configuration: config),
            tokenProvider: { "token" },
            onUnauthorized: {}
        )
        let repository = RemoteProfileRepository(apiClient: apiClient)

        let updated = try await repository.updateProfile(
            request: ProfileUpdateRequest(
                nickname: "新昵称",
                facultyCode: 11,
                majorCode: nil,
                enrollment: nil,
                bio: "",
                birthday: "",
                location: nil,
                hometown: nil
            )
        )

        XCTAssertEqual(updated.nickname, "新昵称")
        XCTAssertEqual(ProfilePatchURLProtocol.requests.map(\.path), ["/api/profile", "/api/user/profile"])
        let patchRequest = try XCTUnwrap(ProfilePatchURLProtocol.requests.first)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: patchRequest.bodyData) as? [String: Any])
        XCTAssertEqual(json["faculty"] as? Int, 11)
        XCTAssertTrue(json["major"] is NSNull)
        XCTAssertTrue(json["enrollment"] is NSNull)
        XCTAssertTrue(json["birthday"] is NSNull)
        XCTAssertTrue(json["location"] is NSNull)
        XCTAssertTrue(json["hometown"] is NSNull)
    }

    func testAccountCenterMapperFiltersLoginRecordsWithoutValidID() {
        let missingID = LoginRecordDTO(
            id: nil,
            ip: "127.0.0.1",
            area: "广州",
            country: nil,
            province: nil,
            city: nil,
            network: "iOS",
            time: RemoteFlexibleString("1704067200")
        )
        let zeroID = LoginRecordDTO(
            id: 0,
            ip: "127.0.0.2",
            area: "广州",
            country: nil,
            province: nil,
            city: nil,
            network: "Web",
            time: RemoteFlexibleString("1704067200")
        )
        let valid = LoginRecordDTO(
            id: 77,
            ip: "113.108.18.12",
            area: "广东 广州",
            country: nil,
            province: nil,
            city: nil,
            network: "iPhone",
            time: RemoteFlexibleString("1704067200")
        )

        let mapped = AccountCenterRemoteMapper.mapLoginRecords([missingID, zeroID, valid])

        XCTAssertEqual(mapped.map(\.id), ["77"])
        XCTAssertEqual(mapped.first?.timeText, "2024-01-01 08:00")
    }

    func testSyncDraftPreservesSavedFacultyAndMajorCodesAbsentFromOptions() async {
        let repository = RecordingProfileRepository()
        repository.profile = UserProfile(
            id: "user-legacy",
            username: "demo",
            nickname: "Demo",
            avatarURL: "",
            college: "旧学院",
            collegeCode: 99,
            major: "旧专业",
            majorCode: "legacy_major",
            grade: "2022",
            bio: "bio"
        )
        let viewModel = ProfileViewModel(repository: repository, sessionState: SessionState())

        await viewModel.loadProfileOptions()
        await viewModel.loadProfile()

        XCTAssertEqual(viewModel.facultyCode, 99)
        XCTAssertEqual(viewModel.majorCode, "legacy_major")
        XCTAssertEqual(viewModel.facultyDisplayName(for: 99), "旧学院")
        XCTAssertEqual(viewModel.majorDisplayName(for: "legacy_major"), "旧专业")

        viewModel.nickname = "Updated Nickname"
        let didSave = await viewModel.saveProfile()

        XCTAssertTrue(didSave)
        XCTAssertEqual(repository.updateRequests.last?.facultyCode, 99)
        XCTAssertEqual(repository.updateRequests.last?.majorCode, "legacy_major")

        viewModel.selectFaculty(code: 11)
        XCTAssertNil(viewModel.majorCode)
    }

    func testProfileViewModelUpdateRepositoryRoutesSubsequentSavesToNewRepository() async {
        let initialRepository = RecordingProfileRepository()
        let reboundRepository = RecordingProfileRepository()
        let viewModel = ProfileViewModel(repository: initialRepository, sessionState: SessionState())

        await viewModel.loadProfile()
        viewModel.updateRepository(reboundRepository)
        viewModel.nickname = "Rebound"

        let didSave = await viewModel.saveProfile()

        XCTAssertTrue(didSave)
        XCTAssertTrue(initialRepository.updateRequests.isEmpty)
        XCTAssertEqual(reboundRepository.updateRequests.count, 1)
        XCTAssertEqual(reboundRepository.updateRequests.first?.nickname, "Rebound")
    }
}

private nonisolated struct ProfilePatchCapturedRequest {
    let path: String
    let bodyData: Data
}

private nonisolated final class ProfilePatchURLProtocol: URLProtocol {
    static nonisolated(unsafe) var requests: [ProfilePatchCapturedRequest] = []
    static nonisolated(unsafe) var responseStub: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(
            ProfilePatchCapturedRequest(
                path: request.url?.path ?? "",
                bodyData: Self.bodyData(from: request)
            )
        )
        guard let stub = Self.responseStub else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        let (response, data) = stub(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func bodyData(from request: URLRequest) -> Data {
        if let httpBody = request.httpBody {
            return httpBody
        }
        guard let stream = request.httpBodyStream else { return Data() }
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
        return data
    }
}

@MainActor
private final class RecordingProfileRepository: ProfileRepository {
    var profile = UserProfile(
        id: "user-1",
        username: "demo",
        nickname: "Demo",
        avatarURL: "",
        college: "计算机科学系",
        major: "软件工程",
        grade: "2023级",
        bio: "bio",
        birthday: "2001-02-03"
    )
    var updateError: Error?
    private(set) var updateRequests: [ProfileUpdateRequest] = []

    func fetchProfile() async throws -> UserProfile {
        profile
    }

    func fetchLocationRegions() async throws -> [ProfileLocationRegion] {
        []
    }

    func fetchProfileOptions() async throws -> ProfileOptions {
        ProfileFormSupport.defaultOptions
    }

    func updateProfile(request: ProfileUpdateRequest) async throws -> UserProfile {
        if let updateError {
            throw updateError
        }
        updateRequests.append(request)
        let options = ProfileFormSupport.defaultOptions
        let collegeLabel = options.faculties.first(where: { $0.code == request.facultyCode })?.label ?? ""
        let majorLabel = request.majorCode.flatMap { code in
            options.faculties.first(where: { $0.code == request.facultyCode })?.majors.first(where: { $0.code == code })?.label
        } ?? ""
        profile = UserProfile(
            id: profile.id,
            username: profile.username,
            nickname: request.nickname,
            avatarURL: profile.avatarURL,
            college: collegeLabel,
            collegeCode: request.facultyCode,
            major: majorLabel,
            majorCode: request.majorCode,
            grade: request.enrollment.map(String.init) ?? "",
            bio: request.bio,
            birthday: request.birthday,
            location: request.location?.displayName ?? "",
            locationSelection: request.location,
            hometown: request.hometown?.displayName ?? "",
            hometownSelection: request.hometown,
            ipArea: profile.ipArea
        )
        return profile
    }
}

@MainActor
private final class SuspendingProfileRepository: ProfileRepository {
    var profile = UserProfile(
        id: "user-1",
        username: "demo",
        nickname: "Demo",
        avatarURL: "",
        college: "计算机科学系",
        major: "软件工程",
        grade: "2023级",
        bio: "bio"
    )
    var onUpdateStarted: (() -> Void)?
    private(set) var updateCallCount = 0
    private var continuation: CheckedContinuation<Void, Never>?

    func fetchProfile() async throws -> UserProfile {
        profile
    }

    func fetchLocationRegions() async throws -> [ProfileLocationRegion] {
        []
    }

    func fetchProfileOptions() async throws -> ProfileOptions {
        ProfileFormSupport.defaultOptions
    }

    func updateProfile(request: ProfileUpdateRequest) async throws -> UserProfile {
        updateCallCount += 1
        onUpdateStarted?()
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
        let options = ProfileFormSupport.defaultOptions
        let collegeLabel = options.faculties.first(where: { $0.code == request.facultyCode })?.label ?? ""
        let majorLabel = request.majorCode.flatMap { code in
            options.faculties.first(where: { $0.code == request.facultyCode })?.majors.first(where: { $0.code == code })?.label
        } ?? ""
        profile = UserProfile(
            id: profile.id,
            username: profile.username,
            nickname: request.nickname,
            avatarURL: profile.avatarURL,
            college: collegeLabel,
            collegeCode: request.facultyCode,
            major: majorLabel,
            majorCode: request.majorCode,
            grade: request.enrollment.map(String.init) ?? "",
            bio: request.bio,
            birthday: request.birthday,
            location: request.location?.displayName ?? "",
            locationSelection: request.location,
            hometown: request.hometown?.displayName ?? "",
            hometownSelection: request.hometown,
            ipArea: profile.ipArea
        )
        return profile
    }

    func resumeUpdate() {
        continuation?.resume()
        continuation = nil
    }
}
