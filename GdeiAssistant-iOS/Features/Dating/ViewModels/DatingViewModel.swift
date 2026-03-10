import Foundation
import Combine

@MainActor
final class DatingViewModel: ObservableObject {
    @Published var profiles: [DatingProfile] = []
    @Published var selectedArea: DatingArea = .girl
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any DatingRepository

    init(repository: any DatingRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard profiles.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            profiles = try await repository.fetchProfiles(filter: DatingFilter(area: selectedArea))
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "卖室友列表加载失败"
        }
    }

    func fetchDetail(profileID: String) async throws -> DatingProfileDetail {
        try await repository.fetchProfileDetail(profileID: profileID)
    }

    func sendPick(profileID: String, content: String) async throws {
        try await repository.sendPick(profileID: profileID, content: content)
    }
}

@MainActor
final class PublishDatingViewModel: ObservableObject {
    @Published var nickname = ""
    @Published var grade = 1
    @Published var area: DatingArea = .girl
    @Published var faculty = ""
    @Published var hometown = ""
    @Published var qq = ""
    @Published var wechat = ""
    @Published var content = ""
    @Published var image: UploadImageAsset?
    @Published var submitState: SubmitState = .idle

    private let repository: any DatingRepository

    init(repository: any DatingRepository) {
        self.repository = repository
    }

    var isFormValid: Bool {
        FormValidationSupport.hasText(nickname) &&
        FormValidationSupport.hasText(faculty) &&
        FormValidationSupport.hasText(hometown) &&
        FormValidationSupport.hasText(content)
    }

    func submit() async -> Bool {
        let trimmedNickname = FormValidationSupport.trimmed(nickname)
        let trimmedFaculty = FormValidationSupport.trimmed(faculty)
        let trimmedHometown = FormValidationSupport.trimmed(hometown)
        let trimmedQQ = FormValidationSupport.trimmed(qq)
        let trimmedWechat = FormValidationSupport.trimmed(wechat)
        let trimmedContent = FormValidationSupport.trimmed(content)

        if let message = FormValidationSupport.requireText(trimmedNickname, message: "请输入昵称") {
            submitState = .failure(message)
            return false
        }
        if trimmedNickname.count > 15 {
            submitState = .failure("昵称长度不合法（1-15字）")
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedFaculty, message: "请输入你的专业") {
            submitState = .failure(message)
            return false
        }
        if trimmedFaculty.count > 12 {
            submitState = .failure("专业长度不合法（1-12字）")
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedHometown, message: "请输入你的家乡") {
            submitState = .failure(message)
            return false
        }
        if trimmedHometown.count > 10 {
            submitState = .failure("家乡长度不合法（1-10字）")
            return false
        }
        if trimmedQQ.isEmpty && trimmedWechat.isEmpty {
            submitState = .failure("QQ号码和微信至少填写一个")
            return false
        }
        if trimmedQQ.count > 15 || trimmedWechat.count > 20 {
            submitState = .failure("联系方式长度不合法")
            return false
        }
        if let message = FormValidationSupport.requireText(trimmedContent, message: "填一下你心目中的那个TA吧") {
            submitState = .failure(message)
            return false
        }
        if trimmedContent.count > 100 {
            submitState = .failure("心动条件不超过100字")
            return false
        }

        submitState = .submitting
        do {
            try await repository.publish(
                draft: DatingPublishDraft(
                    nickname: trimmedNickname,
                    grade: grade,
                    area: area,
                    faculty: trimmedFaculty,
                    hometown: trimmedHometown,
                    qq: trimmedQQ.isEmpty ? nil : trimmedQQ,
                    wechat: trimmedWechat.isEmpty ? nil : trimmedWechat,
                    content: trimmedContent,
                    image: image
                )
            )
            submitState = .success("发布成功")
            return true
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "发布失败")
            return false
        }
    }
}

@MainActor
final class DatingCenterViewModel: ObservableObject {
    @Published var selectedTab: DatingCenterTab = .received
    @Published var receivedItems: [DatingReceivedPick] = []
    @Published var sentItems: [DatingSentPick] = []
    @Published var myPosts: [DatingMyPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var actionMessage: String?

    let focusedPickID: String?
    let focusedProfileID: String?

    private let repository: any DatingRepository

    init(
        repository: any DatingRepository,
        focusedPickID: String? = nil,
        focusedProfileID: String? = nil
    ) {
        self.repository = repository
        self.focusedPickID = focusedPickID
        self.focusedProfileID = focusedProfileID
    }

    var currentFocusID: String? {
        switch selectedTab {
        case .received, .sent:
            return focusedPickID
        case .posts:
            return focusedProfileID
        }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            switch selectedTab {
            case .received:
                receivedItems = try await repository.fetchReceivedPicks(start: 0)
            case .sent:
                sentItems = try await repository.fetchSentPicks()
            case .posts:
                myPosts = try await repository.fetchMyPosts()
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "互动中心加载失败"
        }
    }

    func updatePickState(id: String, state: DatingPickStatus) async {
        do {
            try await repository.updatePickState(pickID: id, state: state)
            actionMessage = state == .accepted ? "已同意，联系方式已展示" : "已拒绝"
            await loadData()
        } catch {
            actionMessage = (error as? LocalizedError)?.errorDescription ?? "操作失败"
        }
    }

    func hideProfile(id: String) async {
        do {
            try await repository.hideProfile(profileID: id)
            actionMessage = "已隐藏"
            await loadData()
        } catch {
            actionMessage = (error as? LocalizedError)?.errorDescription ?? "隐藏失败"
        }
    }
}
