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
        guard let payment = ChargeRemoteMapper.mapPayment(dto, amount: amount) else {
            throw NetworkError.noData
        }
        return payment
    }

    func fetchChargeOrder(orderId: String) async throws -> ChargeOrder {
        var allowedOrderIdCharacters = CharacterSet.urlPathAllowed
        allowedOrderIdCharacters.remove(charactersIn: "/")
        let encodedOrderId = orderId.addingPercentEncoding(withAllowedCharacters: allowedOrderIdCharacters) ?? orderId
        let dto: ChargeOrderDTO = try await apiClient.get(
            "/card/charge/orders/\(encodedOrderId)",
            requiresAuth: true
        )
        guard let order = ChargeRemoteMapper.mapOrder(dto) else {
            throw NetworkError.noData
        }
        return order
    }

    func fetchRecentChargeOrders(page: Int, size: Int, status: String?) async throws -> [ChargeOrder] {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        if let normalizedStatus = status?.trimmingCharacters(in: .whitespacesAndNewlines), !normalizedStatus.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: normalizedStatus))
        }
        let dtos: [ChargeOrderDTO] = try await apiClient.get(
            "/card/charge/orders",
            queryItems: queryItems,
            requiresAuth: true
        )
        return dtos.compactMap(ChargeRemoteMapper.mapOrder)
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
