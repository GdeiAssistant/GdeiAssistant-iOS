import Foundation

@MainActor
final class MockHomeRepository: HomeRepository {
    func fetchDashboard() async throws -> HomeDashboard {
        try await Task.sleep(nanoseconds: 350_000_000)
        return MockFactory.makeHomeDashboard()
    }
}
