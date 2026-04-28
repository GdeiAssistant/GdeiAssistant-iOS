import Foundation

@MainActor
final class MockChargeRepository: ChargeRepository {
    func fetchCardInfo() async throws -> CampusCardDashboard {
        try await Task.sleep(for: .milliseconds(250))
        return CampusCardDashboard(
            info: CampusCardInfo(
                cardNumber: "6212261234567890",
                ownerName: "模拟用户",
                balance: 52.50,
                status: .normal,
                lastUpdated: "刚刚更新"
            ),
            transactions: []
        )
    }

    func submitCharge(amount: Int, password: String) async throws -> ChargePayment {
        guard !password.isEmpty else { throw NetworkError.server(code: 400, message: localizedString("charge.passwordEmpty")) }
        try await Task.sleep(for: .milliseconds(500))
        let order = ChargeOrder(
            orderId: "mock-charge-order-\(amount)",
            amount: amount,
            status: "PAYMENT_SESSION_CREATED",
            message: localizedString("charge.order.status.paymentSessionCreated"),
            createdAt: "刚刚创建",
            updatedAt: "刚刚更新",
            submittedAt: nil,
            completedAt: nil,
            retryAfter: nil
        )
        return ChargePayment(
            alipayURL: "https://gdeiassistant.cn/?mockCharge=\(amount)",
            cookies: [PaymentCookie(name: "mock_session", value: "session_\(Int(Date().timeIntervalSince1970))", domain: "gdeiassistant.cn")],
            order: order
        )
    }

    func fetchChargeOrder(orderId: String) async throws -> ChargeOrder {
        try await Task.sleep(for: .milliseconds(200))
        return mockOrders.first { $0.orderId == orderId } ?? ChargeOrder(
            orderId: orderId,
            amount: nil,
            status: "UNKNOWN",
            message: localizedString("charge.order.status.unknown"),
            createdAt: nil,
            updatedAt: "刚刚更新",
            submittedAt: nil,
            completedAt: nil,
            retryAfter: 60
        )
    }

    func fetchRecentChargeOrders(page: Int, size: Int, status: String?) async throws -> [ChargeOrder] {
        try await Task.sleep(for: .milliseconds(200))
        let normalizedStatus = status?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let filteredOrders = mockOrders.filter { order in
            guard let normalizedStatus, !normalizedStatus.isEmpty else { return true }
            return order.normalizedStatus == normalizedStatus
        }
        let safePage = max(page, 0)
        let safeSize = max(size, 0)
        let start = safePage * safeSize
        guard safeSize > 0, start < filteredOrders.count else { return [] }
        return Array(filteredOrders.dropFirst(start).prefix(safeSize))
    }

    private var mockOrders: [ChargeOrder] {
        [
            ChargeOrder(
                orderId: "mock-charge-order-50",
                amount: 50,
                status: "PAYMENT_SESSION_CREATED",
                message: localizedString("charge.order.status.paymentSessionCreated"),
                createdAt: "10 分钟前",
                updatedAt: "刚刚更新",
                submittedAt: nil,
                completedAt: nil,
                retryAfter: nil
            ),
            ChargeOrder(
                orderId: "mock-charge-order-20",
                amount: 20,
                status: "PROCESSING",
                message: localizedString("charge.order.status.processing"),
                createdAt: "20 分钟前",
                updatedAt: "5 分钟前",
                submittedAt: nil,
                completedAt: nil,
                retryAfter: 60
            )
        ]
    }
}
