import Foundation
import CryptoKit

enum ChargeRemoteMapper {
    /// The shared HMAC secret – must match the backend `REQUEST_VALIDATE_TOKEN` env var.
    private static let hmacSecret = "7UnEVKNng3XV/eBcsL1/lRIANRfXcoPT"

    nonisolated static func chargeFormFields(amount: Int, password: String) -> [FormFieldValue] {
        let timestamp = String(Int64(Date().timeIntervalSince1970 * 1000))
        let payload = "amount=\(amount)&timestamp=\(timestamp)"
        let hmac = hmacSHA256(secret: hmacSecret, data: payload)
        return [
            FormFieldValue(name: "amount", value: String(amount)),
            FormFieldValue(name: "password", value: password),
            FormFieldValue(name: "hmac", value: hmac),
            FormFieldValue(name: "timestamp", value: timestamp),
        ]
    }

    nonisolated static func mapPayment(_ dto: ChargeResponseDTO) -> ChargePayment? {
        guard let url = dto.alipayURL, !url.isEmpty else { return nil }
        let cookies = (dto.cookieList ?? []).compactMap { cookie -> PaymentCookie? in
            guard let name = cookie.name, let value = cookie.value, let domain = cookie.domain,
                  !name.isEmpty, !domain.isEmpty else { return nil }
            return PaymentCookie(name: name, value: value, domain: domain)
        }
        return ChargePayment(alipayURL: url, cookies: cookies)
    }

    private nonisolated static func hmacSHA256(secret: String, data: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(data.utf8), using: key)
        return signature.map { String(format: "%02x", $0) }.joined()
    }
}
