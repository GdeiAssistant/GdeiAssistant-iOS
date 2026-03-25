import Foundation

@MainActor
final class MockCardRepository: CardRepository {
    private var isReportedLoss = false

    func fetchDashboard(on date: Date) async throws -> CampusCardDashboard {
        try await Task.sleep(nanoseconds: 250_000_000)
        return MockFactory.makeCardDashboard(isLoss: isReportedLoss, queryDate: date)
    }

    func reportLoss(request: CardLossRequest) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)

        let password = FormValidationSupport.trimmed(request.cardPassword)
        guard !password.isEmpty else {
            throw NetworkError.server(code: 400, message: localizedString("card.passwordEmpty"))
        }
        guard password == "246810" else {
            throw NetworkError.server(code: 400, message: localizedString("card.mockInvalidPassword"))
        }

        isReportedLoss = true
    }
}
