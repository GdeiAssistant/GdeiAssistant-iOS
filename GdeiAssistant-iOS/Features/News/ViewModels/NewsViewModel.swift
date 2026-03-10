import Foundation
import Combine

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var selectedCategory: NewsCategory = .teaching
    @Published var items: [NewsItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedItem: NewsItem?

    private let repository: any NewsRepository

    init(repository: any NewsRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard items.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await repository.fetchNews(category: selectedCategory, start: 0, size: 15)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "新闻通知加载失败"
        }
    }
}
