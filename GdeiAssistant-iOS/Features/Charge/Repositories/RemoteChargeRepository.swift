import Foundation

@MainActor
final class RemoteChargeRepository: ChargeRepository {
    private let apiClient: APIClient
    private let idempotencyKeyGenerator: ChargeIdempotencyKeyGenerator

    init(
        apiClient: APIClient,
        idempotencyKeyGenerator: ChargeIdempotencyKeyGenerator = ChargeIdempotencyKeyGenerator()
    ) {
        self.apiClient = apiClient
        self.idempotencyKeyGenerator = idempotencyKeyGenerator
    }

    func fetchCardInfo() async throws -> CampusCardDashboard {
        let infoDTO: CardInfoDTO = try await apiClient.get("/card/info", requiresAuth: true)
        return CardRemoteMapper.mapDashboard(infoDTO: infoDTO, queryDTO: nil)
    }

    func submitCharge(amount: Int, password: String) async throws -> ChargePayment {
        let fields = ChargeRemoteMapper.chargeFormFields(amount: amount, password: password)
        let idempotencyKey = idempotencyKeyGenerator.generate()
        let dto: ChargeResponseDTO = try await apiClient.postForm(
            "/card/charge",
            fields: fields,
            requiresAuth: true,
            headers: ["Idempotency-Key": idempotencyKey]
        )
        guard let payment = ChargeRemoteMapper.mapPayment(dto) else {
            throw NetworkError.noData
        }
        return payment
    }
}

struct ChargeIdempotencyKeyGenerator {
    private let makeKey: () -> String

    init(makeKey: @escaping () -> String = { UUID().uuidString }) {
        self.makeKey = makeKey
    }

    func generate() -> String {
        makeKey()
    }
}
