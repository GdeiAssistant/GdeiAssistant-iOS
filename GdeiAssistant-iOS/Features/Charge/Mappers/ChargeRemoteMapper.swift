import Foundation

enum ChargeRemoteMapper {
    nonisolated static func chargeFormFields(amount: Int, password: String) -> [FormFieldValue] {
        return [
            FormFieldValue(name: "amount", value: String(amount)),
            FormFieldValue(name: "password", value: password)
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
}
