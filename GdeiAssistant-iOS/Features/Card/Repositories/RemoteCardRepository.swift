import Foundation

@MainActor
final class RemoteCardRepository: CardRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchDashboard(on date: Date) async throws -> CampusCardDashboard {
        let infoDTO: CardInfoDTO = try await apiClient.get("/card/info", requiresAuth: true)

        do {
            let queryDTO: CardQueryResultDTO = try await apiClient.post(
                "/card/query",
                body: CardRemoteMapper.queryRequest(for: date),
                requiresAuth: true
            )
            return CardRemoteMapper.mapDashboard(infoDTO: infoDTO, queryDTO: queryDTO)
        } catch {
            return CardRemoteMapper.mapDashboard(infoDTO: infoDTO, queryDTO: nil)
        }
    }

    func reportLoss(request: CardLossRequest) async throws {
        let dto = CardRemoteMapper.mapLossRequest(request)
        let queryItems = CardRemoteMapper.mapLossQueryItems(dto)
        let _: EmptyPayload = try await apiClient.post(
            "/card/lost",
            queryItems: queryItems,
            requiresAuth: true
        )
    }
}
