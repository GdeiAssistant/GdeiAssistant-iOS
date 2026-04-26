import Foundation

struct PrivacySettingsDTO: Codable {
    let facultyOpen: Bool?
    let majorOpen: Bool?
    let locationOpen: Bool?
    let hometownOpen: Bool?
    let introductionOpen: Bool?
    let enrollmentOpen: Bool?
    let ageOpen: Bool?
    let cacheAllow: Bool?
    let robotsIndexAllow: Bool?
}

struct PhoneAttributionDTO: Decodable {
    let code: Int?
    let flag: String?
    let name: String?
}

struct PhoneStatusDTO: Decodable {
    let username: String?
    let phone: String?
    let code: Int?
}

struct FeedbackSubmitRemoteDTO: Codable {
    let content: String
    let contact: String?
    let type: String?
}

struct LoginRecordDTO: Decodable {
    let id: Int?
    let ip: String?
    let area: String?
    let country: String?
    let province: String?
    let city: String?
    let network: String?
    let time: RemoteFlexibleString?
}

struct CampusCredentialStatusDTO: Decodable {
    let hasActiveConsent: Bool?
    let hasSavedCredential: Bool?
    let quickAuthEnabled: Bool?
    let consentedAt: RemoteFlexibleString?
    let revokedAt: RemoteFlexibleString?
    let policyDate: RemoteFlexibleString?
    let effectiveDate: RemoteFlexibleString?
    let maskedCampusAccount: RemoteFlexibleString?
}

struct CampusCredentialConsentRequestDTO: Encodable {
    let scene: String
    let policyDate: String?
    let effectiveDate: String?
}

struct CampusCredentialQuickAuthRequestDTO: Encodable {
    let enabled: Bool
}
