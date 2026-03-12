import Foundation

@MainActor
protocol NewsRepository {
    func fetchNews(start: Int, size: Int) async throws -> [NewsItem]
}

@MainActor
final class SwitchingNewsRepository: NewsRepository {
    private let environment: AppEnvironment
    private let remoteRepository: any NewsRepository
    private let mockRepository: any NewsRepository

    init(environment: AppEnvironment, remoteRepository: any NewsRepository, mockRepository: any NewsRepository) {
        self.environment = environment
        self.remoteRepository = remoteRepository
        self.mockRepository = mockRepository
    }

    func fetchNews(start: Int, size: Int) async throws -> [NewsItem] {
        try await currentRepository.fetchNews(start: start, size: size)
    }

    private var currentRepository: any NewsRepository {
        environment.dataSourceMode == .mock ? mockRepository : remoteRepository
    }
}
