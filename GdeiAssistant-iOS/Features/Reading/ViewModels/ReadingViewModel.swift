import Foundation
import Combine

@MainActor
final class ReadingViewModel: ObservableObject {
    @Published var items: [ReadingItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any ReadingRepository

    init(repository: any ReadingRepository) {
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
            items = try await repository.fetchReadings()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "专题阅读加载失败"
        }
    }
}
