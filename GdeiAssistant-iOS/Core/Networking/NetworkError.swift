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
            return "请求地址无效"
        case .invalidResponse:
            return "服务响应异常"
        case .transport:
            return "网络连接失败，请检查网络后重试"
        case .unauthorized:
            return "登录状态已过期，请重新登录"
        case .httpStatus(let status, let message):
            return message.isEmpty ? "请求失败（\(status)）" : message
        case .server(_, let message):
            return message.isEmpty ? "服务暂时不可用，请稍后重试" : message
        case .noData:
            return "服务返回数据为空"
        case .decoding:
            return "数据解析失败"
        }
    }
}
