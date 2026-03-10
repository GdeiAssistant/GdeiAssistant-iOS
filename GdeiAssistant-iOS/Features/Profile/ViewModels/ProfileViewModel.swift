import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var locationRegions: [ProfileLocationRegion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEditing = false
    @Published var isSaving = false
    @Published var saveErrorMessage: String?
    @Published var nickname = ""
    @Published var college = "未选择"
    @Published var major = "未选择"
    @Published var grade = ""
    @Published var bio = ""
    @Published var birthday = ""
    @Published var location = ""
    @Published var hometown = ""

    private let repository: any ProfileRepository
    private let sessionState: SessionState
    private var cancellables = Set<AnyCancellable>()
    private var locationSelection: ProfileLocationSelection?
    private var hometownSelection: ProfileLocationSelection?

    init(repository: any ProfileRepository, sessionState: SessionState) {
        self.repository = repository
        self.sessionState = sessionState
        self.profile = sessionState.currentUser
        bindSessionState()
    }

    var displayProfile: UserProfile? {
        sessionState.currentUser ?? profile
    }

    var facultyOptions: [String] {
        ProfileFormSupport.facultyOptions
    }

    var majorOptions: [String] {
        ProfileFormSupport.majorOptions(for: college)
    }

    var enrollmentOptions: [String] {
        ["未选择"] + ProfileFormSupport.enrollmentOptions
    }

    var canSelectMajor: Bool {
        ProfileFormSupport.canSelectMajor(for: college)
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "加载个人信息失败"
        }
    }

    func loadLocationRegions() async {
        do {
            locationRegions = try await repository.fetchLocationRegions()
        } catch {
            if profile == nil {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "加载资料选项失败"
            }
        }
    }

    func startEditing() {
        guard let displayProfile else { return }
        syncDraft(with: displayProfile)
        saveErrorMessage = nil
        isEditing = true
    }

    func cancelEditing() {
        saveErrorMessage = nil
        if let displayProfile {
            syncDraft(with: displayProfile)
        }
        isEditing = false
    }

    func selectCollege(_ value: String) {
        college = value
        let options = majorOptions
        if !options.contains(major) {
            major = "未选择"
        }
    }

    func selectMajor(_ value: String) {
        guard canSelectMajor else {
            saveErrorMessage = "请先选择院系"
            return
        }
        major = value
    }

    func selectEnrollment(_ value: String) {
        grade = value == "未选择" ? "" : value
    }

    func updateBirthday(date: Date) {
        birthday = Self.dateFormatter.string(from: date)
    }

    func clearBirthday() {
        birthday = ""
    }

    func updateLocationSelection(_ selection: ProfileLocationSelection) {
        locationSelection = selection
        location = selection.displayName
    }

    func updateHometownSelection(_ selection: ProfileLocationSelection) {
        hometownSelection = selection
        hometown = selection.displayName
    }

    func saveProfile() async -> Bool {
        guard isFormValid else {
            saveErrorMessage = "请填写昵称"
            return false
        }

        isSaving = true
        saveErrorMessage = nil
        defer { isSaving = false }

        let request = ProfileUpdateRequest(
            nickname: FormValidationSupport.trimmed(nickname),
            college: FormValidationSupport.trimmed(college).isEmpty ? "未选择" : FormValidationSupport.trimmed(college),
            major: FormValidationSupport.trimmed(major).isEmpty ? "未选择" : FormValidationSupport.trimmed(major),
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
            isEditing = false
            return true
        } catch {
            saveErrorMessage = (error as? LocalizedError)?.errorDescription ?? "保存资料失败"
            return false
        }
    }

    private func syncDraft(with profile: UserProfile) {
        nickname = profile.nickname
        college = profile.college.isEmpty ? "未选择" : profile.college
        major = profile.major.isEmpty ? "未选择" : profile.major
        grade = profile.grade
        bio = profile.bio
        birthday = profile.birthday
        location = profile.location
        hometown = profile.hometown
        locationSelection = nil
        hometownSelection = nil
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
                if !self.isEditing {
                    self.syncDraft(with: user)
                }
            }
            .store(in: &cancellables)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
