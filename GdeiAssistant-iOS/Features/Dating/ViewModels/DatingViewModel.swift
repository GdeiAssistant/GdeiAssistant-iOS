import Foundation
import Combine

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
