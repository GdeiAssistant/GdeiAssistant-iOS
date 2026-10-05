import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case transport(Error)
    case unauthorized
    case httpStatus(Int, String)
    case server(code: Int, message: String)
    /// Contract-stable business failure with machine-readable `errorCode` (e.g. SOCIAL PRIVACY_RESTRICTED).
    case contract(statusCode: Int, message: String, errorCode: String)
    case noData
    case decoding(Error)

    var errorCode: String? {
        switch self {
        case .contract(_, _, let errorCode):
            return errorCode
        default:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return localizedString("network.invalidURL")
        case .invalidResponse:
            return localizedString("network.invalidResponse")
        case .transport:
            return localizedString("network.transport")
        case .unauthorized:
            return localizedString("network.unauthorized")
        case .httpStatus(let status, let message):
            return message.isEmpty ? String(format: localizedString("network.httpStatus"), Int(status)) : message
        case .server(_, let message):
            return message.isEmpty ? localizedString("network.serverUnavailable") : message
        case .contract(_, let message, let errorCode):
            if !message.isEmpty {
                return message
            }
            return SocialErrorCode.localizedMessage(for: errorCode)
                ?? localizedString("network.serverUnavailable")
        case .noData:
            return localizedString("network.noData")
        case .decoding:
            return localizedString("network.decoding")
        }
    }
}

enum SocialErrorCode {
    static let authRequired = "AUTH_REQUIRED"
    static let userNotFound = "USER_NOT_FOUND"
    static let conversationNotFound = "CONVERSATION_NOT_FOUND"
    static let contactUnavailable = "CONTACT_UNAVAILABLE"
    static let privacyRestricted = "PRIVACY_RESTRICTED"
    static let invalidRequest = "INVALID_REQUEST"
    static let clientMessageConflict = "CLIENT_MESSAGE_CONFLICT"
    static let rateLimited = "RATE_LIMITED"

    nonisolated static func localizedMessage(for errorCode: String) -> String? {
        switch errorCode {
        case authRequired:
            return localizedString("network.unauthorized")
        case userNotFound:
            return localizedString("social.error.userNotFound")
        case conversationNotFound:
            return localizedString("social.error.conversationNotFound")
        case contactUnavailable:
            return localizedString("social.error.contactUnavailable")
        case privacyRestricted:
            return localizedString("social.error.privacyRestricted")
        case invalidRequest:
            return localizedString("social.error.invalidRequest")
        case clientMessageConflict:
            return localizedString("social.error.clientMessageConflict")
        case rateLimited:
            return localizedString("social.error.rateLimited")
        default:
            return nil
        }
    }
}
