import Foundation

struct LoginRequestDTO: Encodable {
    let username: String
    let password: String
    let campusCredentialConsent: Bool?
    let consentScene: String?
    let policyDate: String?
    let effectiveDate: String?
}

struct LoginResponseDTO: Decodable {
    let token: String
}
