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
        return ChargePayment(
            alipayURL: "https://gdeiassistant.cn/?mockCharge=\(amount)",
            cookies: [PaymentCookie(name: "mock_session", value: "session_\(Int(Date().timeIntervalSince1970))", domain: "gdeiassistant.cn")]
        )
    }
}
