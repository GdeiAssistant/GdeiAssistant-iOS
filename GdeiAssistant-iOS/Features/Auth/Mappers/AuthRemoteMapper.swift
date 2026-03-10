import Foundation

enum AuthRemoteMapper {
    static func mapLoginRequest(_ request: LoginRequest) -> LoginRequestDTO {
        LoginRequestDTO(
            username: request.username,
            password: request.password
        )
    }

    static func mapLoginResponse(_ dto: LoginResponseDTO) -> LoginResponse {
        LoginResponse(token: dto.token)
    }
}
