import Foundation
import Combine

@MainActor
final class FeedbackViewModel: ObservableObject {
    @Published var selectedType = localizedString("feedback.defaultType")
    @Published var content = ""
    @Published var contact = ""
    @Published var submitState: SubmitState = .idle

    let typeOptions = [
        localizedString("feedback.type.crash"),
        localizedString("feedback.type.account"),
        localizedString("feedback.type.campus"),
        localizedString("feedback.type.community"),
        localizedString("feedback.type.malfunction"),
        localizedString("feedback.type.other")
    ]

    private let repository: any AccountCenterRepository

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(content)
    }

    func submit() async {
        guard isFormValid else {
            submitState = .failure(localizedString("feedback.contentEmpty"))
            return
        }

        submitState = .submitting
        do {
            try await repository.submitFeedback(
                FeedbackSubmission(
                    content: FormValidationSupport.trimmed(content),
                    contact: FormValidationSupport.hasText(contact) ? FormValidationSupport.trimmed(contact) : nil,
                    type: selectedType
                )
            )
            submitState = .success(localizedString("feedback.success"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("feedback.failed"))
        }
    }
}

@MainActor
final class DownloadDataViewModel: ObservableObject {
    @Published var status = DownloadDataStatus(state: .idle, message: localizedString("downloadData.description"), downloadURL: nil)
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any AccountCenterRepository

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            status = try await repository.fetchDownloadStatus()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("downloadData.loadFailed")
        }
    }

    func startExport() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            status = try await repository.startDataExport()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("downloadData.exportFailed")
        }
    }

    func fetchDownloadURL() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            status = try await repository.fetchDownloadURL()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("downloadData.urlFailed")
        }
    }
}

@MainActor
final class AvatarEditViewModel: ObservableObject {
    @Published var avatarState = AvatarState(url: nil)
    @Published var submitState: SubmitState = .idle
    @Published var isLoading = false

    private let repository: any AccountCenterRepository
    private let sessionState: SessionState

    init(repository: any AccountCenterRepository, sessionState: SessionState) {
        self.repository = repository
        self.sessionState = sessionState
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            avatarState = try await repository.fetchAvatarState()
            updateSessionAvatarURL(avatarState.url)
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("avatar.loadFailed"))
        }
    }

    func uploadAvatar(_ avatar: UploadImageAsset) async {
        submitState = .submitting
        do {
            avatarState = try await repository.uploadAvatar(avatar)
            updateSessionAvatarURL(avatarState.url)
            submitState = .success(localizedString("avatar.updateSuccess"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("avatar.updateFailed"))
        }
    }

    func deleteAvatar() async {
        submitState = .submitting
        do {
            avatarState = try await repository.deleteAvatar()
            updateSessionAvatarURL(avatarState.url)
            submitState = .success(localizedString("avatar.deleteSuccess"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("avatar.deleteFailed"))
        }
    }

    private func updateSessionAvatarURL(_ url: String?) {
        guard let currentUser = sessionState.currentUser else { return }
        sessionState.currentUser = UserProfile(
            id: currentUser.id,
            username: currentUser.username,
            nickname: currentUser.nickname,
            avatarURL: url ?? "",
            college: currentUser.college,
            major: currentUser.major,
            grade: currentUser.grade,
            bio: currentUser.bio,
            birthday: currentUser.birthday,
            location: currentUser.location,
            hometown: currentUser.hometown,
            ipArea: currentUser.ipArea
        )
    }
}

@MainActor
final class DeleteAccountViewModel: ObservableObject {
    @Published var password = ""
    @Published var agreed = false
    @Published var submitState: SubmitState = .idle

    private let repository: any AccountCenterRepository

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    var canSubmit: Bool {
        agreed && FormValidationSupport.hasText(password)
    }

    func submit() async {
        guard canSubmit else {
            submitState = .failure(localizedString("deleteAccount.validation"))
            return
        }
        submitState = .submitting
        do {
            try await repository.deleteAccount(password: FormValidationSupport.trimmed(password))
            submitState = .success(localizedString("deleteAccount.success"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("deleteAccount.failed"))
        }
    }
}
