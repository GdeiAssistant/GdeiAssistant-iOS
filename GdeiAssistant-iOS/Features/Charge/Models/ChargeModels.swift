import Foundation

struct ChargePayment: Codable, Hashable {
    let alipayURL: String
    let cookies: [PaymentCookie]
    let order: ChargeOrder?

    init(alipayURL: String, cookies: [PaymentCookie], order: ChargeOrder? = nil) {
        self.alipayURL = alipayURL
        self.cookies = cookies
        self.order = order
    }
}

struct PaymentCookie: Codable, Hashable {
    let name: String
    let value: String
    let domain: String
}

struct ChargeOrder: Codable, Hashable, Identifiable {
    let orderId: String?
    let amount: Int?
    let status: String?
    let message: String?
    let createdAt: String?
    let updatedAt: String?
    let submittedAt: String?
    let completedAt: String?
    let retryAfter: Int?

    var id: String {
        orderId?.nonEmptyValue
            ?? [status, updatedAt, createdAt, amount.map(String.init)].compactMap { $0 }.joined(separator: "-")
    }

    var normalizedStatus: String {
        status?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? "UNKNOWN"
    }

    var localizedStatusLabel: String {
        switch normalizedStatus {
        case "CREATED":
            return localizedString("charge.order.statusLabel.created")
        case "PROCESSING":
            return localizedString("charge.order.statusLabel.processing")
        case "PAYMENT_SESSION_CREATED":
            return localizedString("charge.order.statusLabel.paymentSessionCreated")
        case "FAILED":
            return localizedString("charge.order.statusLabel.failed")
        case "MANUAL_REVIEW":
            return localizedString("charge.order.statusLabel.manualReview")
        default:
            return localizedString("charge.order.statusLabel.unknown")
        }
    }

    var localizedStatusMessage: String {
        switch normalizedStatus {
        case "CREATED":
            return localizedString("charge.order.status.created")
        case "PROCESSING":
            return localizedString("charge.order.status.processing")
        case "PAYMENT_SESSION_CREATED":
            return localizedString("charge.order.status.paymentSessionCreated")
        case "FAILED":
            return localizedString("charge.order.status.failed")
        case "MANUAL_REVIEW":
            return localizedString("charge.order.status.manualReview")
        case "UNKNOWN":
            return localizedString("charge.order.status.unknown")
        default:
            return localizedString("charge.order.status.fallback")
        }
    }
}

private extension String {
    var nonEmptyValue: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
