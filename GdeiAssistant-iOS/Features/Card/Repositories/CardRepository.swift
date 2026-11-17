import Foundation

@MainActor
protocol CardRepository {
    func fetchDashboard(on date: Date) async throws -> CampusCardDashboard
    func reportLoss(request: CardLossRequest) async throws
}
