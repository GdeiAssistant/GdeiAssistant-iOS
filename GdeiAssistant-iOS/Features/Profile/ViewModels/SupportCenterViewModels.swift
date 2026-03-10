import Foundation
import Combine

@MainActor
final class FeedbackViewModel: ObservableObject {
    @Published var selectedType = "应用功能异常"
    @Published var content = ""
    @Published var contact = ""
    @Published var submitState: SubmitState = .idle

    let typeOptions = [
        "闪退或卡顿",
        "账号与安全",
        "校园服务问题",
        "社区内容问题",
        "应用功能异常",
        "其它"
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
            submitState = .failure("请填写反馈内容")
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
            submitState = .success("感谢反馈，我们会尽快处理")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "提交反馈失败")
        }
    }
}

@MainActor
final class DownloadDataViewModel: ObservableObject {
    @Published var status = DownloadDataStatus(state: .idle, message: "你可以随时导出个人数据副本。", downloadURL: nil)
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "加载导出状态失败"
        }
    }

    func startExport() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            status = try await repository.startDataExport()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "提交导出失败"
        }
    }

    func fetchDownloadURL() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            status = try await repository.fetchDownloadURL()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "获取下载地址失败"
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
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "加载头像失败")
        }
    }

    func uploadAvatar(_ avatar: UploadImageAsset) async {
        submitState = .submitting
        do {
            avatarState = try await repository.uploadAvatar(avatar)
            updateSessionAvatarURL(avatarState.url)
            submitState = .success("头像已更新")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "上传头像失败")
        }
    }

    func deleteAvatar() async {
        submitState = .submitting
        do {
            avatarState = try await repository.deleteAvatar()
            updateSessionAvatarURL(avatarState.url)
            submitState = .success("已恢复默认头像")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "删除头像失败")
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
            submitState = .failure("请确认风险提示并输入账号密码")
            return
        }
        submitState = .submitting
        do {
            try await repository.deleteAccount(password: FormValidationSupport.trimmed(password))
            submitState = .success("账号注销已提交")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "注销账号失败")
        }
    }
}
