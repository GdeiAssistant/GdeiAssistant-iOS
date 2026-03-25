import Foundation

enum DownloadExportState: Int, Codable, CaseIterable {
    case idle = 0
    case exporting = 1
    case exported = 2

    var title: String {
        switch self {
        case .idle:
            return localizedString("downloadData.state.idle")
        case .exporting:
            return localizedString("downloadData.state.exporting")
        case .exported:
            return localizedString("downloadData.state.exported")
        }
    }
}

struct PrivacySettings: Codable, Hashable {
    var facultyOpen: Bool
    var majorOpen: Bool
    var locationOpen: Bool
    var hometownOpen: Bool
    var introductionOpen: Bool
    var enrollmentOpen: Bool
    var ageOpen: Bool
    var cacheAllow: Bool
    var robotsIndexAllow: Bool

    static let `default` = PrivacySettings(
        facultyOpen: false,
        majorOpen: false,
        locationOpen: false,
        hometownOpen: false,
        introductionOpen: true,
        enrollmentOpen: false,
        ageOpen: false,
        cacheAllow: false,
        robotsIndexAllow: false
    )
}

struct LoginRecordItem: Identifiable, Hashable {
    let id: String
    let timeText: String
    let ip: String
    let area: String
    let device: String
    let statusText: String
}

struct ContactBindingStatus: Hashable {
    let isBound: Bool
    let rawValue: String?
    let maskedValue: String
    let note: String
    let countryCode: Int?
    let username: String?
}

struct PhoneAttribution: Identifiable, Hashable {
    let id: Int
    let code: Int
    let flag: String
    let name: String

    var displayText: String {
        let prefix = flag.isEmpty ? "" : "\(flag) "
        return "\(prefix)\(name) (+\(code))"
    }
}

struct PhoneBindRequest: Hashable {
    let areaCode: Int
    let phone: String
    let randomCode: String
}

struct FeedbackSubmission: Hashable {
    let content: String
    let contact: String?
    let type: String?
}

struct DownloadDataStatus: Hashable {
    let state: DownloadExportState
    let message: String
    let downloadURL: String?
}

struct AvatarState: Hashable {
    let url: String?
}
