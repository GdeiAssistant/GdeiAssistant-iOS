import Foundation

enum AppConstants {
    enum Brand {
        nonisolated static let displayName = "广东第二师范学院校园助手系统"
        nonisolated static let shortDisplayName = "校园助手系统"
    }

    enum Debug {
        nonisolated static let mockCredentialsHint = "Mock 账号：gdeiassistant  密码：gdeiassistant"
        nonisolated static let bootstrapTimeoutMessage = "启动超时，请重试或重新登录"
    }

    enum Delivery {
        nonisolated static let defaultTaskName = "代收"
        nonisolated static let defaultPickupCode = "00000000000"
    }

    enum API {
        static let devBaseURLString = "http://localhost:8080/api"
        static let stagingBaseURLString = "https://gdeiassistant.azurewebsites.net/api"
        static let prodBaseURLString = "https://gdeiassistant.azurewebsites.net/api"

        static let authorizationHeader = "Authorization"
        static let clientTypeHeader = "X-Client-Type"
        static let contentTypeHeader = "Content-Type"
        static let acceptHeader = "Accept"
        static let jsonMimeType = "application/json"
        static let formURLEncodedMimeType = "application/x-www-form-urlencoded; charset=utf-8"
        static let clientType = "IOS"

        static let successCodes: Set<Int> = [0, 200]
        static let unauthorizedBusinessCodes: Set<Int> = [401, 40101, 100401, 1001]
    }

    enum UserDefaultsKeys {
        static let useMockData = "use_mock_data"
        static let networkEnvironment = "network_environment"
    }
}
