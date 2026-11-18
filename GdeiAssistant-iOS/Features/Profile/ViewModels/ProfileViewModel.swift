import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    static let unselectedMajorCode = "unselected"

    @Published var profile: UserProfile?
    @Published var profileOptions = ProfileFormSupport.defaultOptions
    @Published var locationRegions: [ProfileLocationRegion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var saveErrorMessage: String?
    @Published var nickname = ""
    @Published var facultyCode = 0
    @Published var majorCode: String?
    @Published var enrollment: Int?
    @Published var bio = ""
    @Published var birthday = ""
    @Published var location = ""
    @Published var hometown = ""

    private var repository: any ProfileRepository
    private let sessionState: SessionState
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedProfileOptions = false
    private var repositoryGeneration = 0
    private var locationSelection: ProfileLocationSelection?
    private var hometownSelection: ProfileLocationSelection?

    init(repository: any ProfileRepository, sessionState: SessionState) {
        self.repository = repository
        self.sessionState = sessionState
        self.profile = sessionState.currentUser
        if let currentUser = sessionState.currentUser {
            syncDraft(with: currentUser)
        }
        bindSessionState()
    }

    // ARC still releases the repository and cancels the Combine subscriptions.
    // No custom actor-bound cleanup requires an isolated deinitializer.
    nonisolated deinit {}

    func updateRepository(_ repository: any ProfileRepository) {
        repositoryGeneration += 1
        self.repository = repository
        hasLoadedProfileOptions = false
        isLoading = false
        isSaving = false
        errorMessage = nil
        saveErrorMessage = nil
    }

    var displayProfile: UserProfile? {
        sessionState.currentUser ?? profile
    }

    var facultyOptions: [ProfileFacultyOption] {
        profileOptions.faculties
    }

    var majorOptions: [ProfileMajorOption] {
        let baseOptions = profileOptions.faculties.first(where: { $0.code == facultyCode })?.majors
            ?? [ProfileMajorOption(code: Self.unselectedMajorCode, label: ProfileFormSupport.unselectedOption)]
        if let majorCode,
           !majorCode.isEmpty,
           majorCode != Self.unselectedMajorCode,
           !baseOptions.contains(where: { $0.code == majorCode }) {
            let fallbackLabel = majorDisplayName(for: majorCode)
            return baseOptions + [ProfileMajorOption(code: majorCode, label: fallbackLabel)]
        }
        return baseOptions
    }

    func facultyDisplayName(
        for code: Int,
        localeIdentifier: String = AppLanguage.currentIdentifier()
    ) -> String {
        if code == 0 {
            return localizedString("profile.notSelected", locale: localeIdentifier)
        }
        let localizedOptions = LocalizedProfileCatalog.catalog(for: localeIdentifier).defaultOptions
        if let label = localizedOptions.faculties.first(where: { $0.code == code })?.label
            ?? profileOptions.faculties.first(where: { $0.code == code })?.label {
            return label
        }
        if displayProfile?.collegeCode == code,
           let savedLabel = displayProfile?.college,
           !savedLabel.isEmpty {
            return savedLabel
        }
        return String(code)
    }

    func majorDisplayName(
        for code: String,
        localeIdentifier: String = AppLanguage.currentIdentifier()
    ) -> String {
        if code == Self.unselectedMajorCode || code.isEmpty {
            return localizedString("profile.notSelected", locale: localeIdentifier)
        }
        let localizedOptions = LocalizedProfileCatalog.catalog(for: localeIdentifier).defaultOptions
        if let label = localizedOptions.faculties
            .first(where: { $0.code == facultyCode })?
            .majors
            .first(where: { $0.code == code })?.label
            ?? profileOptions.faculties
                .first(where: { $0.code == facultyCode })?
                .majors
                .first(where: { $0.code == code })?.label {
            return label
        }
        if displayProfile?.majorCode == code,
           let savedLabel = displayProfile?.major,
           !savedLabel.isEmpty {
            return savedLabel
        }
        return code
    }

    func enrollmentDisplayName(
        for year: Int?,
        localeIdentifier: String = AppLanguage.currentIdentifier()
    ) -> String {
        year.map(String.init) ?? localizedString("profile.notSelected", locale: localeIdentifier)
    }

    var enrollmentOptions: [Int?] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return [nil] + Array(2014...currentYear)
    }

    var canSelectMajor: Bool {
        facultyCode != 0
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
        let generation = repositoryGeneration
        isLoading = true
        errorMessage = nil

        defer { if generation == repositoryGeneration { isLoading = false } }

        do {
            let fetchedProfile = try await repository.fetchProfile()
            guard generation == repositoryGeneration else { return }
            profile = fetchedProfile
            sessionState.currentUser = fetchedProfile
            syncDraft(with: fetchedProfile)
        } catch {
            guard generation == repositoryGeneration else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("profile.loadFailed")
        }
    }

    func loadLocationRegions() async {
        let generation = repositoryGeneration
        do {
            let regions = try await repository.fetchLocationRegions()
            guard generation == repositoryGeneration else { return }
            locationRegions = regions
        } catch {
            guard generation == repositoryGeneration else { return }
            if profile == nil {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("profile.optionsFailed")
            }
        }
    }

    func loadProfileOptions() async {
        let generation = repositoryGeneration
        do {
            let options = try await repository.fetchProfileOptions()
            guard generation == repositoryGeneration else { return }
            profileOptions = options
            hasLoadedProfileOptions = true
            if let displayProfile {
                syncDraft(with: displayProfile)
            }
        } catch {
            guard generation == repositoryGeneration else { return }
            if profile == nil {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("profile.optionsFailed")
            }
        }
    }

    func selectFaculty(code: Int) {
        facultyCode = code
        let baseMajors = profileOptions.faculties.first(where: { $0.code == code })?.majors ?? []
        let validCodes = Set(baseMajors.map(\.code))
        if let majorCode, !validCodes.contains(majorCode) {
            self.majorCode = nil
        }
    }

    func selectMajor(code: String) {
        guard canSelectMajor else {
            saveErrorMessage = localizedString("profile.selectFacultyFirst")
            return
        }
        majorCode = (code == Self.unselectedMajorCode || code.isEmpty) ? nil : code
    }

    func selectEnrollment(_ year: Int?) {
        enrollment = year
    }

    func isEnrollmentOptionSelected(_ year: Int?) -> Bool {
        enrollment == year
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

        let generation = repositoryGeneration
        isSaving = true
        saveErrorMessage = nil
        defer { if generation == repositoryGeneration { isSaving = false } }

        let request = ProfileUpdateRequest(
            nickname: FormValidationSupport.trimmed(nickname),
            facultyCode: facultyCode,
            majorCode: majorCode,
            enrollment: enrollment,
            bio: FormValidationSupport.trimmed(bio),
            birthday: FormValidationSupport.trimmed(birthday),
            location: locationSelection,
            hometown: hometownSelection
        )

        do {
            let updatedProfile = try await repository.updateProfile(request: request)
            guard generation == repositoryGeneration else { return false }
            profile = updatedProfile
            sessionState.currentUser = updatedProfile
            syncDraft(with: updatedProfile)
            return true
        } catch {
            guard generation == repositoryGeneration else { return false }
            if let persistedProfile = displayProfile {
                syncDraft(with: persistedProfile)
            }
            saveErrorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("profile.saveFailed")
            return false
        }
    }

    private func syncDraft(with profile: UserProfile) {
        nickname = profile.nickname
        if let code = profile.collegeCode, code != 0 {
            facultyCode = code
        } else if !profile.college.isEmpty,
                  let resolvedCode = profileOptions.facultyCode(for: profile.college) {
            facultyCode = resolvedCode
        } else {
            facultyCode = 0
        }

        let selectedFaculty = profileOptions.faculties.first(where: { $0.code == facultyCode })
        if let code = profile.majorCode?.trimmingCharacters(in: .whitespacesAndNewlines),
           !code.isEmpty,
           code != Self.unselectedMajorCode {
            majorCode = code
        } else if !profile.major.isEmpty,
                  let facultyLabel = selectedFaculty?.label,
                  let resolvedMajorCode = profileOptions.majorCode(for: facultyLabel, majorLabel: profile.major),
                  resolvedMajorCode != Self.unselectedMajorCode {
            majorCode = resolvedMajorCode
        } else {
            majorCode = nil
        }

        enrollment = try? ProfileRemoteMapper.enrollmentYear(from: profile.grade)
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
