import Foundation
import Combine

@MainActor
final class DatingHallViewModel: ObservableObject {
    @Published var selectedArea: DatingArea = .girl
    @Published var profiles: [DatingProfile] = []
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
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "卖室友大厅加载失败"
        }
    }

    func updateArea(_ area: DatingArea) async {
        selectedArea = area
        await refresh()
    }

    func fetchDetail(profileID: String) async throws -> DatingProfileDetail {
        try await repository.fetchProfileDetail(profileID: profileID)
    }

    func publish(draft: DatingPublishDraft) async throws {
        try await repository.publishProfile(draft: draft)
        await refresh()
    }

    func submitPick(profileID: String, content: String) async throws {
        try await repository.submitPick(profileID: profileID, content: content)
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

    private let repository: any DatingRepository

    init(repository: any DatingRepository) {
        self.repository = repository
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            switch selectedTab {
            case .received:
                receivedItems = try await repository.fetchReceivedPicks()
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

@MainActor
final class PublishDatingViewModel: ObservableObject {
    @Published var nickname = ""
    @Published var selectedGrade = 1
    @Published var selectedArea: DatingArea = .girl
    @Published var selectedFaculty = ProfileFormSupport.unselectedOption
    @Published var hometown = ""
    @Published var qq = ""
    @Published var wechat = ""
    @Published var content = ""
    @Published var image: UploadImageAsset?
    @Published var facultyOptions: [String] = ProfileFormSupport.defaultOptions.facultyOptions
    @Published var submitState: SubmitState = .idle

    private let profileRepository: any ProfileRepository

    init(profileRepository: any ProfileRepository) {
        self.profileRepository = profileRepository
    }

    var isFormValid: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedFaculty != ProfileFormSupport.unselectedOption &&
        !hometown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadFacultyOptionsIfNeeded() async {
        do {
            let options = try await profileRepository.fetchProfileOptions()
            facultyOptions = options.facultyOptions
        } catch {
            facultyOptions = ProfileFormSupport.defaultOptions.facultyOptions
        }
    }

    func buildDraft() -> DatingPublishDraft? {
        let normalizedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedFaculty = selectedFaculty.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedHometown = hometown.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedQQ = qq.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedWechat = wechat.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if normalizedNickname.isEmpty {
            submitState = .failure("请输入昵称")
            return nil
        }
        if normalizedNickname.count > 15 {
            submitState = .failure("昵称不能超过 15 个字")
            return nil
        }
        if normalizedFaculty.isEmpty || normalizedFaculty == ProfileFormSupport.unselectedOption {
            submitState = .failure("请选择学院")
            return nil
        }
        if normalizedHometown.isEmpty {
            submitState = .failure("请输入家乡")
            return nil
        }
        if normalizedHometown.count > 10 {
            submitState = .failure("家乡不能超过 10 个字")
            return nil
        }
        if normalizedContent.isEmpty {
            submitState = .failure("请输入自我介绍")
            return nil
        }
        if normalizedContent.count > 100 {
            submitState = .failure("自我介绍不能超过 100 个字")
            return nil
        }
        if normalizedQQ.count > 15 {
            submitState = .failure("QQ 不能超过 15 个字符")
            return nil
        }
        if normalizedWechat.count > 20 {
            submitState = .failure("微信不能超过 20 个字符")
            return nil
        }

        return DatingPublishDraft(
            nickname: normalizedNickname,
            grade: selectedGrade,
            area: selectedArea,
            faculty: normalizedFaculty,
            hometown: normalizedHometown,
            qq: normalizedQQ.isEmpty ? nil : normalizedQQ,
            wechat: normalizedWechat.isEmpty ? nil : normalizedWechat,
            content: normalizedContent,
            image: image
        )
    }
}
