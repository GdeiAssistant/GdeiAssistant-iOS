import Foundation

@MainActor
final class RemoteDataCenterRepository: DataCenterRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func queryElectricity(_ query: ElectricityQuery) async throws -> ElectricityBill {
        let fields = DataCenterRemoteMapper.mapElectricityQuery(query)
        let response: ElectricityBillRemoteDTO = try await apiClient.postForm(
            "/data/electricfees",
            fields: fields,
            requiresAuth: false
        )
        return DataCenterRemoteMapper.mapElectricityBill(response)
    }

    func fetchYellowPages() async throws -> [YellowPageCategory] {
        let dto: YellowPageResultRemoteDTO = try await apiClient.get("/data/yellowpage", requiresAuth: false)
        return DataCenterRemoteMapper.mapYellowPages(dto)
    }
}
