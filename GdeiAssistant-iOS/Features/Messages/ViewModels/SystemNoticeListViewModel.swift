import Foundation
import Combine

@MainActor
final class SystemNoticeListViewModel: ObservableObject {
    @Published var items: [AppNotificationItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var canLoadMore = true
    @Published var errorMessage: String?
    @Published var loadMoreErrorMessage: String?

    private let repository: any MessagesRepository
    private let pageSize = 5
    private var nextStart = 0

    init(repository: any MessagesRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard items.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        loadMoreErrorMessage = nil
        nextStart = 0
        canLoadMore = true
        defer { isLoading = false }

        do {
            let page = try await repository.fetchAnnouncementPage(start: 0, size: pageSize)
            items = page
            nextStart = page.count
            canLoadMore = page.count == pageSize
        } catch {
            items = []
            canLoadMore = false
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "系统通知公告加载失败"
        }
    }

    func loadMoreIfNeeded(currentItem item: AppNotificationItem) async {
        guard canLoadMore, !isLoadingMore, items.last?.id == item.id else { return }

        isLoadingMore = true
        loadMoreErrorMessage = nil
        defer { isLoadingMore = false }

        do {
            let page = try await repository.fetchAnnouncementPage(start: nextStart, size: pageSize)
            items.append(contentsOf: page)
            nextStart += page.count
            canLoadMore = page.count == pageSize
        } catch {
            loadMoreErrorMessage = (error as? LocalizedError)?.errorDescription ?? "系统通知公告加载失败"
        }
    }
}
