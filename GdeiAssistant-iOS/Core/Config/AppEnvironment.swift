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

    var allowsRuntimeDebugOptions: Bool {
        isDebug && AppConstants.API.allowsRuntimeDebugOptions
    }

    init(
        networkEnvironment: NetworkEnvironment,
        dataSourceMode: DataSourceMode,
        isDebug: Bool? = nil,
        clientType: String? = nil
    ) {
        let resolvedIsDebug = isDebug ?? _isDebugAssertConfiguration()
        self.isDebug = resolvedIsDebug
        self.clientType = clientType ?? AppConstants.API.clientType
        self.networkEnvironment = Self.sanitizedNetworkEnvironment(
            networkEnvironment,
            isDebug: resolvedIsDebug
        )
        self.baseURL = self.networkEnvironment.baseURL
        self.dataSourceMode = Self.sanitizedDataSourceMode(
            dataSourceMode,
            isDebug: resolvedIsDebug
        )
    }

    func updateDataSourceMode(_ mode: DataSourceMode) {
        dataSourceMode = sanitizedDataSourceMode(mode)
    }

    func updateNetworkEnvironment(_ environment: NetworkEnvironment) {
        let nextEnvironment = sanitizedNetworkEnvironment(environment)
        networkEnvironment = nextEnvironment
        baseURL = nextEnvironment.baseURL
    }

    private func sanitizedDataSourceMode(_ mode: DataSourceMode) -> DataSourceMode {
        Self.sanitizedDataSourceMode(mode, isDebug: isDebug)
    }

    private func sanitizedNetworkEnvironment(_ environment: NetworkEnvironment) -> NetworkEnvironment {
        Self.sanitizedNetworkEnvironment(environment, isDebug: isDebug)
    }

    private static func allowsRuntimeDebugOptions(isDebug: Bool) -> Bool {
        isDebug && AppConstants.API.allowsRuntimeDebugOptions
    }

    private static func sanitizedDataSourceMode(
        _ mode: DataSourceMode,
        isDebug: Bool
    ) -> DataSourceMode {
        allowsRuntimeDebugOptions(isDebug: isDebug) ? mode : .remote
    }

    private static func sanitizedNetworkEnvironment(
        _ environment: NetworkEnvironment,
        isDebug: Bool
    ) -> NetworkEnvironment {
        allowsRuntimeDebugOptions(isDebug: isDebug) ? environment : .prod
    }
}
