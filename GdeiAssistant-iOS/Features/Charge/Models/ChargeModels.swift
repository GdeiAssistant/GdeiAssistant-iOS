import Foundation

struct ChargePayment: Codable, Hashable {
    let alipayURL: String
    let cookies: [PaymentCookie]
}

struct PaymentCookie: Codable, Hashable {
    let name: String
    let value: String
    let domain: String
}
