import Foundation

struct ChargeResponseDTO: Decodable {
    let alipayURL: String?
    let cookieList: [CookieDTO]?
    let orderId: String?
    let status: String?
    let message: String?
    let retryAfter: Int?
}

struct CookieDTO: Decodable {
    let name: String?
    let value: String?
    let domain: String?
}

struct ChargeOrderDTO: Decodable {
    let orderId: String?
    let amount: Int?
    let status: String?
    let message: String?
    let createdAt: String?
    let updatedAt: String?
    let submittedAt: String?
    let completedAt: String?
    let retryAfter: Int?
}
