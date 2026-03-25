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
