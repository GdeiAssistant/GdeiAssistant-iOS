import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case transport(Error)
    case unauthorized
    case httpStatus(Int, String)
    case server(code: Int, message: String)
    case noData
    case decoding(Error)

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
        case .noData:
            return localizedString("network.noData")
        case .decoding:
            return localizedString("network.decoding")
        }
    }
}
