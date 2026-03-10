import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var dashboard: HomeDashboard?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any HomeRepository

    init(repository: any HomeRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard dashboard == nil else { return }
        await loadDashboard()
    }

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            dashboard = try await repository.fetchDashboard()
        } catch {
            dashboard = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "加载功能主页失败"
        }
    }

    func refresh() async {
        await loadDashboard()
    }
}
