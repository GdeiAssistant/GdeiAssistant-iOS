import Foundation

@MainActor
final class RemoteChargeRepository: ChargeRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchCardInfo() async throws -> CampusCardDashboard {
        let infoDTO: CardInfoDTO = try await apiClient.get("/card/info", requiresAuth: true)
        return CardRemoteMapper.mapDashboard(infoDTO: infoDTO, queryDTO: nil)
    }

    func submitCharge(amount: Int, password: String) async throws -> ChargePayment {
        let fields = ChargeRemoteMapper.chargeFormFields(amount: amount, password: password)
        let dto: ChargeResponseDTO = try await apiClient.postForm(
            "/card/charge",
            fields: fields,
            requiresAuth: true
        )
        guard let payment = ChargeRemoteMapper.mapPayment(dto) else {
            throw NetworkError.noData
        }
        return payment
    }
}
