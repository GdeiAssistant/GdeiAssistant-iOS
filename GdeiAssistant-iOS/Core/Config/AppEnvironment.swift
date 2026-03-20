import Foundation
import Combine

enum DataSourceMode: String, CaseIterable, Codable {
    case remote
    case mock

    var displayName: String {
        rawValue
    }
}

enum NetworkEnvironment: String, CaseIterable, Codable {
    case dev
    case staging
    case prod

    var displayName: String {
        rawValue.uppercased()
    }

    var baseURL: URL {
        let rawValue: String
        switch self {
        case .dev:
            rawValue = AppConstants.API.devBaseURLString
        case .staging:
            rawValue = AppConstants.API.stagingBaseURLString
        case .prod:
            rawValue = AppConstants.API.prodBaseURLString
        }
        // swiftlint:disable:next force_unwrapping
        return URL(string: rawValue)!
    }
}

@MainActor
final class AppEnvironment: ObservableObject {
    @Published var baseURL: URL
    @Published var dataSourceMode: DataSourceMode
    @Published var networkEnvironment: NetworkEnvironment

    let isDebug: Bool
    let clientType: String

    init(
        networkEnvironment: NetworkEnvironment,
        dataSourceMode: DataSourceMode,
        isDebug: Bool? = nil,
        clientType: String? = nil
    ) {
        self.networkEnvironment = networkEnvironment
        self.baseURL = networkEnvironment.baseURL
        self.dataSourceMode = dataSourceMode
        self.isDebug = isDebug ?? _isDebugAssertConfiguration()
        self.clientType = clientType ?? AppConstants.API.clientType
    }

    func updateDataSourceMode(_ mode: DataSourceMode) {
        dataSourceMode = mode
    }

    func updateNetworkEnvironment(_ environment: NetworkEnvironment) {
        networkEnvironment = environment
        baseURL = environment.baseURL
    }
}
