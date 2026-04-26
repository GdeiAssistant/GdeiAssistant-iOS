import Foundation

struct LoginRequest: Codable {
    let username: String
    let password: String
    let campusCredentialConsent: Bool?
    let consentScene: String?
    let policyDate: String?
    let effectiveDate: String?

    init(
        username: String,
        password: String,
        consentMetadata: CampusCredentialConsentMetadata? = nil
    ) {
        self.username = username
        self.password = password
        self.campusCredentialConsent = consentMetadata == nil ? nil : true
        self.consentScene = consentMetadata?.scene
        self.policyDate = consentMetadata?.policyDate
        self.effectiveDate = consentMetadata?.effectiveDate
    }
}
