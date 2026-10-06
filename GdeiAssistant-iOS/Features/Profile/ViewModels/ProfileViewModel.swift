import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var profileOptions = ProfileFormSupport.defaultOptions
    @Published var locationRegions: [ProfileLocationRegion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var saveErrorMessage: String?
    @Published var nickname = ""
    @Published var college = ProfileFormSupport.unselectedOption
    @Published var major = ProfileFormSupport.unselectedOption
    @Published var grade = ""
    @Published var bio = ""
    @Published var birthday = ""
    @Published var location = ""
    @Published var hometown = ""

    private let repository: any ProfileRepository
    private let sessionState: SessionState
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedProfileOptions = false
    private var locationSelection: ProfileLocationSelection?
    private var hometownSelection: ProfileLocationSelection?

    init(repository: any ProfileRepository, sessionState: SessionState) {
        self.repository = repository
        self.sessionState = sessionState
        self.profile = sessionState.currentUser
        bindSessionState()
    }

    // ARC still releases the repository and cancels the Combine subscriptions.
    // No custom actor-bound cleanup requires an isolated deinitializer.
    nonisolated deinit {}

    var displayProfile: UserProfile? {
        sessionState.currentUser ?? profile
    }

    var facultyOptions: [String] {
        profileOptions.facultyOptions
    }

    var majorOptions: [String] {
        profileOptions.majorOptions(for: college)
    }

    func selectionOptionDisplayName(_ value: String, localeIdentifier: String = AppLanguage.currentIdentifier()) -> String {
        let localizedOptions = LocalizedProfileCatalog.catalog(for: localeIdentifier).defaultOptions
        if let faculty = profileOptions.faculties.first(where: { $0.label == value }),
           let localizedFaculty = localizedOptions.faculties.first(where: { $0.code == faculty.code }) {
            return faculty.code == 0 ? localizedString("profile.notSelected", locale: localeIdentifier) : localizedFaculty.label
        }
        if let faculty = profileOptions.faculties.first(where: { $0.label == college }),
           let option = faculty.majors.first(where: { $0.label == value }),
           let localizedFaculty = localizedOptions.faculties.first(where: { $0.code == faculty.code }),
           let localizedMajor = localizedFaculty.majors.first(where: { $0.code == option.code }) {
            return option.code == "unselected" ? localizedString("profile.notSelected", locale: localeIdentifier) : localizedMajor.label
        }
        return value == ProfileFormSupport.unselectedOption ? localizedString("profile.notSelected", locale: localeIdentifier) : value
    }

    var enrollmentOptions: [String] {
        [ProfileFormSupport.unselectedOption] + ProfileFormSupport.enrollmentOptions
    }

    var selectedEnrollmentOption: String {
        grade.isEmpty ? ProfileFormSupport.unselectedOption : grade
    }

    var canSelectMajor: Bool {
        profileOptions.canSelectMajor(for: college)
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(nickname)
    }

    var birthdayDate: Date {
        Self.dateFormatter.date(from: birthday) ?? Date()
    }

    func loadIfNeeded() async {
        if profile == nil {
            await loadProfile()
        }
        if !hasLoadedProfileOptions {
            await loadProfileOptions()
        }
        if locationRegions.isEmpty {
            await loadLocationRegions()
        }
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let fetchedProfile = try await repository.fetchProfile()
            profile = fetchedProfile
            sessionState.currentUser = fetchedProfile
            syncDraft(with: fetchedProfile)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("profile.loadFailed")
        }
    }

    func loadLocationRegions() async {
        do {
            locationRegions = try await repository.fetchLocationRegions()
        } catch {
            if profile == nil {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("profile.optionsFailed")
            }
        }
    }

    func loadProfileOptions() async {
        do {
            profileOptions = try await repository.fetchProfileOptions()
            hasLoadedProfileOptions = true
            if let displayProfile {
                syncDraft(with: displayProfile)
            }
        } catch {
            if profile == nil {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("profile.optionsFailed")
            }
        }
    }

    func selectCollege(_ value: String) {
        college = value
        let options = majorOptions
        if !options.contains(major) {
            major = ProfileFormSupport.unselectedOption
        }
    }

    func selectMajor(_ value: String) {
        guard canSelectMajor else {
            saveErrorMessage = localizedString("profile.selectFacultyFirst")
            return
        }
        major = value
    }

    func selectEnrollment(_ value: String) {
        grade = value == ProfileFormSupport.unselectedOption ? "" : value
    }

    func isEnrollmentOptionSelected(_ value: String) -> Bool {
        selectedEnrollmentOption == value
    }

    func updateBirthday(date: Date) {
        birthday = Self.dateFormatter.string(from: date)
    }

    func clearBirthday() {
        birthday = ""
    }

    func applyBirthdayEditorChange(
        selectedDate: Date,
        hadExistingBirthday: Bool,
        didChangeSelection: Bool,
        didRequestClear: Bool
    ) {
        if didRequestClear {
            clearBirthday()
        } else if !hadExistingBirthday && !didChangeSelection {
            clearBirthday()
        } else {
            updateBirthday(date: selectedDate)
        }
    }

    func updateLocationSelection(_ selection: ProfileLocationSelection) {
        locationSelection = selection
        location = selection.displayName
    }

    func updateHometownSelection(_ selection: ProfileLocationSelection) {
        hometownSelection = selection
        hometown = selection.displayName
    }

    @discardableResult
    func saveProfile() async -> Bool {
        guard !isSaving else {
            return false
        }

        guard isFormValid else {
            saveErrorMessage = localizedString("profile.nicknameEmpty")
            return false
        }

        isSaving = true
        saveErrorMessage = nil
        defer { isSaving = false }

        // The repository fetches current-language options when saving. Preserve
        // the cached selection codes while resolving their submission labels.
        let selectedFaculty = profileOptions.faculties.first(where: { $0.label == college })
        let selectedMajor = selectedFaculty?.majors.first(where: { $0.label == major })
        let currentFaculty = LocalizedProfileCatalog.current.defaultOptions.faculties.first(where: { $0.code == selectedFaculty?.code })
        let submissionCollege = currentFaculty?.label ?? college
        let submissionMajor = currentFaculty?.majors.first(where: { $0.code == selectedMajor?.code })?.label ?? major
        let request = ProfileUpdateRequest(
            nickname: FormValidationSupport.trimmed(nickname),
            college: FormValidationSupport.trimmed(submissionCollege).isEmpty ? ProfileFormSupport.unselectedOption : FormValidationSupport.trimmed(submissionCollege),
            major: FormValidationSupport.trimmed(submissionMajor).isEmpty ? ProfileFormSupport.unselectedOption : FormValidationSupport.trimmed(submissionMajor),
            grade: FormValidationSupport.trimmed(grade),
            bio: FormValidationSupport.trimmed(bio),
            birthday: FormValidationSupport.trimmed(birthday),
            location: locationSelection,
            hometown: hometownSelection
        )

        do {
            let updatedProfile = try await repository.updateProfile(request: request)
            profile = updatedProfile
            sessionState.currentUser = updatedProfile
            syncDraft(with: updatedProfile)
            return true
        } catch {
            if let persistedProfile = displayProfile {
                syncDraft(with: persistedProfile)
            }
            saveErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("profile.saveFailed")
            return false
        }
    }

    private func syncDraft(with profile: UserProfile) {
        nickname = profile.nickname
        let codedCollege = profileOptions.faculties.first(where: { $0.code == profile.collegeCode })?.label
        let normalizedCollege = codedCollege ?? (profile.college.isEmpty ? ProfileFormSupport.unselectedOption : profile.college)
        let validMajors = profileOptions.majorOptions(for: normalizedCollege)
        college = facultyOptions.contains(normalizedCollege) ? normalizedCollege : ProfileFormSupport.unselectedOption
        if let majorCode = profile.majorCode,
           let restoredMajor = profileOptions.majorLabel(for: college, majorCode: majorCode),
           validMajors.contains(restoredMajor) {
            major = restoredMajor
        } else {
            major = validMajors.contains(profile.major) ? profile.major : ProfileFormSupport.unselectedOption
        }
        grade = profile.grade
        bio = profile.bio
        birthday = profile.birthday
        location = profile.location
        hometown = profile.hometown
        locationSelection = profile.locationSelection
        hometownSelection = profile.hometownSelection
    }

    private func bindSessionState() {
        sessionState.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                guard let self else { return }
                guard let user else {
                    self.profile = nil
                    return
                }
                self.profile = user
                self.syncDraft(with: user)
            }
            .store(in: &cancellables)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = AppLanguage.locale(for: UserPreferences.currentLocale)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
