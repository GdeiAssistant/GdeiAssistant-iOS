import Foundation

@MainActor
protocol SpareRepository {
    func queryRooms(_ query: SpareQuery) async throws -> [SpareRoomItem]
}
