import Foundation

enum CampusCredentialDefaults {
    static let policyDate = "2026-04-25"
    static let effectiveDate = "2026-05-11"
    static let loginScene = "LOGIN"
    static let settingsScene = "SETTINGS"
}

struct CampusCredentialConsentMetadata: Codable, Hashable {
    let scene: String
    let policyDate: String
    let effectiveDate: String

    init(
        scene: String = CampusCredentialDefaults.loginScene,
        policyDate: String = CampusCredentialDefaults.policyDate,
        effectiveDate: String = CampusCredentialDefaults.effectiveDate
    ) {
        self.scene = scene
        self.policyDate = policyDate
        self.effectiveDate = effectiveDate
    }
}

struct CampusCredentialStatus: Codable, Hashable {
    var hasActiveConsent: Bool
    var hasSavedCredential: Bool
    var quickAuthEnabled: Bool
    var consentedAt: String?
    var revokedAt: String?
    var policyDate: String?
    var effectiveDate: String?
    var maskedCampusAccount: String?

    static let empty = CampusCredentialStatus(
        hasActiveConsent: false,
        hasSavedCredential: false,
        quickAuthEnabled: false,
        consentedAt: nil,
        revokedAt: nil,
        policyDate: nil,
        effectiveDate: nil,
        maskedCampusAccount: nil
    )
}
