import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class ProfileViewModelTests: XCTestCase {
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
