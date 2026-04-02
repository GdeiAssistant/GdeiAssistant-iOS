import Foundation

private final class AppBuildSettingsBundleToken: NSObject {}

private enum AppBuildSettings {
    private enum Keys {
        static let apiBaseURLDevelopment = "GDEIAPIBaseURLDevelopment"
        static let apiBaseURLStaging = "GDEIAPIBaseURLStaging"
        static let apiBaseURLProduction = "GDEIAPIBaseURLProduction"
        static let defaultNetworkEnvironment = "GDEIDefaultNetworkEnvironment"
        static let allowRuntimeDebugOptions = "GDEIAllowRuntimeDebugOptions"
    }

    private static let configurationBundle: Bundle = {
        if let info = Bundle.main.infoDictionary,
           info[Keys.apiBaseURLDevelopment] != nil {
            return Bundle.main
        }
        return Bundle(for: AppBuildSettingsBundleToken.self)
    }()

    static func apiBaseURLDevelopment(default defaultValue: String) -> String {
        string(for: Keys.apiBaseURLDevelopment, default: defaultValue)
    }

    static func apiBaseURLStaging(default defaultValue: String) -> String {
        string(for: Keys.apiBaseURLStaging, default: defaultValue)
    }

    static func apiBaseURLProduction(default defaultValue: String) -> String {
        string(for: Keys.apiBaseURLProduction, default: defaultValue)
    }

    static func defaultNetworkEnvironment(default defaultValue: String) -> String {
        string(for: Keys.defaultNetworkEnvironment, default: defaultValue)
    }

    static func allowRuntimeDebugOptions(default defaultValue: Bool) -> Bool {
        bool(for: Keys.allowRuntimeDebugOptions, default: defaultValue)
    }

    private static func string(for key: String, default defaultValue: String) -> String {
        if let value = configurationBundle.object(forInfoDictionaryKey: key) as? String,
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }

        if let value = ProcessInfo.processInfo.environment[key],
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }

        return defaultValue
    }

    private static func bool(for key: String, default defaultValue: Bool) -> Bool {
        if let value = configurationBundle.object(forInfoDictionaryKey: key) as? Bool {
            return value
        }

        if let value = configurationBundle.object(forInfoDictionaryKey: key) as? String {
            return NSString(string: value).boolValue
        }

        if let value = ProcessInfo.processInfo.environment[key] {
            return NSString(string: value).boolValue
        }

        return defaultValue
    }
}

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
        static let devBaseURLString = AppBuildSettings.apiBaseURLDevelopment(default: "http://localhost:8080/api")
        static let stagingBaseURLString = AppBuildSettings.apiBaseURLStaging(
            default: "https://gdeiassistant.azurewebsites.net/api"
        )
        static let prodBaseURLString = AppBuildSettings.apiBaseURLProduction(default: "https://gdeiassistant.cn/api")
        static let defaultNetworkEnvironment = AppBuildSettings.defaultNetworkEnvironment(default: "prod")
        static let allowsRuntimeDebugOptions = AppBuildSettings.allowRuntimeDebugOptions(
            default: _isDebugAssertConfiguration()
        )

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
        nonisolated static let useMockData = "use_mock_data"
        nonisolated static let networkEnvironment = "network_environment"
        nonisolated static let selectedLocale = "selected_locale"
        nonisolated static let selectedTheme = "selected_theme"
        nonisolated static let fontScaleStep = "font_scale_step"
    }
}
