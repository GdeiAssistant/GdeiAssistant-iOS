import Foundation

enum AuthRemoteMapper {
    static func mapLoginRequest(_ request: LoginRequest) -> LoginRequestDTO {
        LoginRequestDTO(
            username: request.username,
            password: request.password,
            campusCredentialConsent: request.campusCredentialConsent,
            consentScene: request.consentScene,
            policyDate: request.policyDate,
            effectiveDate: request.effectiveDate
        )
    }

    static func mapLoginResponse(_ dto: LoginResponseDTO) -> LoginResponse {
        LoginResponse(token: dto.token)
    }
}
