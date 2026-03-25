import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func testMapProfileReadsStructuredFieldsFromRemoteDTO() {
        let dto = UserProfileDTO(
            username: "demo",
            nickname: "Demo",
            avatar: "https://example.com/avatar.png",
            faculty: ProfileValueLabelIntDTO(code: 11, label: "计算机科学系"),
            major: ProfileValueLabelStringDTO(code: "software_engineering", label: "软件工程"),
            enrollment: "2023",
            location: ProfileRemoteLocationValueDTO(region: "CN", state: "44", city: "1", displayName: "中国 广东 广州"),
            hometown: ProfileRemoteLocationValueDTO(region: "CN", state: "44", city: "5", displayName: "中国 广东 汕头"),
            introduction: "bio",
            birthday: "2001-02-03",
            ipArea: "广东省",
            age: 23
        )

        let profile = ProfileRemoteMapper.mapProfile(dto)

        XCTAssertEqual(profile.collegeCode, 11)
        XCTAssertEqual(profile.majorCode, "software_engineering")
        XCTAssertEqual(profile.locationSelection?.regionCode, "CN")
        XCTAssertEqual(profile.locationSelection?.cityCode, "1")
        XCTAssertEqual(profile.hometownSelection?.cityCode, "5")
    }

    func testMapProfileOptionsReadsStructuredMajorOptions() {
        let options = ProfileRemoteMapper.mapProfileOptions(
            ProfileOptionsDTO(
                faculties: [
                    ProfileFacultyOptionDTO(
                        code: 11,
                        label: "计算机科学系",
                        majors: [
                            ProfileMajorOptionDTO(code: "unselected", label: "未选择"),
                            ProfileMajorOptionDTO(code: "software_engineering", label: "软件工程")
                        ]
                    )
                ],
                marketplaceItemTypes: nil,
                lostFoundItemTypes: nil,
                lostFoundModes: nil
            )
        )

        XCTAssertEqual(options.faculties.first?.majors.first?.code, "unselected")
        XCTAssertEqual(options.majorCode(for: "计算机科学系", majorLabel: "软件工程"), "software_engineering")
        XCTAssertEqual(options.majorLabel(for: "计算机科学系", majorCode: "software_engineering"), "软件工程")
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

        XCTAssertTrue(viewModel.isEnrollmentOptionSelected(ProfileFormSupport.unselectedOption))
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

        XCTAssertEqual(viewModel.major, "软件工程")
        XCTAssertEqual(viewModel.location, "中国 广东 广州")
        XCTAssertTrue(await viewModel.saveProfile())
        XCTAssertEqual(repository.updateRequests.last?.location?.cityCode, "1")
        XCTAssertEqual(repository.updateRequests.last?.hometown?.cityCode, "5")
    }

    func testMockProfileRepositoryPersistsStructuredProfileValuesOnUpdate() async throws {
        let repository = MockProfileRepository()

        _ = try await repository.fetchProfileOptions()

        let updatedProfile = try await repository.updateProfile(
            request: ProfileUpdateRequest(
                nickname: "新昵称",
                college: "计算机科学系",
                major: "软件工程",
                grade: "2024",
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
        XCTAssertEqual(updatedProfile.locationSelection?.cityCode, "1")
        XCTAssertEqual(updatedProfile.hometownSelection?.cityCode, "5")
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
        profile = UserProfile(
            id: profile.id,
            username: profile.username,
            nickname: request.nickname,
            avatarURL: profile.avatarURL,
            college: request.college,
            major: request.major,
            grade: request.grade,
            bio: request.bio,
            birthday: request.birthday,
            location: request.location?.displayName ?? "",
            hometown: request.hometown?.displayName ?? "",
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
        profile = UserProfile(
            id: profile.id,
            username: profile.username,
            nickname: request.nickname,
            avatarURL: profile.avatarURL,
            college: request.college,
            major: request.major,
            grade: request.grade,
            bio: request.bio,
            birthday: request.birthday,
            location: request.location?.displayName ?? "",
            hometown: request.hometown?.displayName ?? "",
            ipArea: profile.ipArea
        )
        return profile
    }

    func resumeUpdate() {
        continuation?.resume()
        continuation = nil
    }
}
