import Foundation

enum ChargeRemoteMapper {
    nonisolated static func chargeFormFields(amount: Int, password: String) -> [FormFieldValue] {
        return [
            FormFieldValue(name: "amount", value: String(amount)),
            FormFieldValue(name: "password", value: password)
        ]
    }

    nonisolated static func mapPayment(_ dto: ChargeResponseDTO, amount: Int? = nil) -> ChargePayment? {
        guard let url = dto.alipayURL, !url.isEmpty else { return nil }
        let cookies = (dto.cookieList ?? []).compactMap { cookie -> PaymentCookie? in
            guard let name = cookie.name, let value = cookie.value, let domain = cookie.domain,
                  !name.isEmpty, !domain.isEmpty else { return nil }
            return PaymentCookie(name: name, value: value, domain: domain)
        }
        let order = mapOrder(
            orderId: dto.orderId,
            amount: amount,
            status: dto.status,
            message: dto.message,
            retryAfter: dto.retryAfter
        )
        return ChargePayment(alipayURL: url, cookies: cookies, order: order)
    }

    nonisolated static func mapOrder(_ dto: ChargeOrderDTO) -> ChargeOrder? {
        mapOrder(
            orderId: dto.orderId,
            amount: dto.amount,
            status: dto.status,
            message: dto.message,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            submittedAt: dto.submittedAt,
            completedAt: dto.completedAt,
            retryAfter: dto.retryAfter
        )
    }

    nonisolated private static func mapOrder(
        orderId: String?,
        amount: Int?,
        status: String?,
        message: String?,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        submittedAt: String? = nil,
        completedAt: String? = nil,
        retryAfter: Int? = nil
    ) -> ChargeOrder? {
        let normalizedOrderId = orderId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedStatus = status?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedOrderId?.isEmpty == false || normalizedStatus?.isEmpty == false else {
            return nil
        }
        return ChargeOrder(
            orderId: normalizedOrderId?.isEmpty == false ? normalizedOrderId : nil,
            amount: amount,
            status: normalizedStatus?.isEmpty == false ? normalizedStatus : nil,
            message: message,
            createdAt: createdAt,
            updatedAt: updatedAt,
            submittedAt: submittedAt,
            completedAt: completedAt,
            retryAfter: retryAfter
        )
    }
}
