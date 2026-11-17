import Foundation

@MainActor
protocol DataCenterRepository {
    func queryElectricity(_ query: ElectricityQuery) async throws -> ElectricityBill
    func fetchYellowPages() async throws -> [YellowPageCategory]
}
