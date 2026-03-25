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
    let regionCode: String?

    nonisolated init(id: Int, code: Int, flag: String, name: String, regionCode: String? = nil) {
        self.id = id
        self.code = code
        self.flag = flag
        self.name = name
        self.regionCode = regionCode ?? Self.regionCode(from: flag)
    }

    nonisolated func displayName(locale: String? = nil) -> String {
        let localeIdentifier = locale ?? UserPreferences.currentLocale
        if let regionCode,
           let localizedName = Locale(identifier: localeIdentifier).localizedString(forRegionCode: regionCode),
           !localizedName.isEmpty {
            return localizedName
        }
        return name.isEmpty ? "+\(code)" : name
    }

    nonisolated var displayText: String {
        displayText(locale: UserPreferences.currentLocale)
    }

    nonisolated func displayText(locale: String? = nil) -> String {
        let prefix = flag.isEmpty ? "" : "\(flag) "
        return "\(prefix)\(displayName(locale: locale)) (+\(code))"
    }

    nonisolated func merged(with overlay: PhoneAttribution) -> PhoneAttribution {
        PhoneAttribution(
            id: code,
            code: code,
            flag: overlay.flag.isEmpty ? flag : overlay.flag,
            name: overlay.name.isEmpty ? name : overlay.name,
            regionCode: overlay.regionCode ?? regionCode
        )
    }

    private nonisolated static func regionCode(from flag: String) -> String? {
        let scalars = Array(flag.unicodeScalars)
        guard scalars.count == 2 else { return nil }
        var result = ""
        for scalar in scalars {
            let value = scalar.value
            guard let asciiScalar = UnicodeScalar(value - 127397) else {
                return nil
            }
            result.unicodeScalars.append(asciiScalar)
        }
        return result
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
    let downloadURL: String?

    nonisolated var localizedMessage: String {
        switch state {
        case .idle:
            return localizedString("downloadData.description")
        case .exporting:
            return localizedString("downloadData.exportingMessage")
        case .exported:
            return localizedString("downloadData.exportedMessage")
        }
    }
}

struct AvatarState: Hashable {
    let url: String?
}
