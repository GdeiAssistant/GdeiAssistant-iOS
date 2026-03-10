import Foundation
import Combine

enum DataSourceMode: String, CaseIterable, Codable {
    case remote
    case mock

    var displayName: String {
        rawValue
    }
}

@MainActor
final class AppEnvironment: ObservableObject {
    @Published var baseURL: URL
    @Published var dataSourceMode: DataSourceMode

    let isDebug: Bool
    let clientType: String

    init(
        baseURL: URL? = nil,
        dataSourceMode: DataSourceMode,
        isDebug: Bool? = nil,
        clientType: String? = nil
    ) {
        self.baseURL = baseURL ?? AppConstants.API.defaultBaseURL
        self.dataSourceMode = dataSourceMode
        self.isDebug = isDebug ?? _isDebugAssertConfiguration()
        self.clientType = clientType ?? AppConstants.API.clientType
    }

    func updateDataSourceMode(_ mode: DataSourceMode) {
        dataSourceMode = mode
    }
}
