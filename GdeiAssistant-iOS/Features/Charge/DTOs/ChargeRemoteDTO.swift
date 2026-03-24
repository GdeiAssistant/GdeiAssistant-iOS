import Foundation

struct ChargeResponseDTO: Decodable {
    let alipayURL: String?
    let cookieList: [CookieDTO]?
}

struct CookieDTO: Decodable {
    let name: String?
    let value: String?
    let domain: String?
}
