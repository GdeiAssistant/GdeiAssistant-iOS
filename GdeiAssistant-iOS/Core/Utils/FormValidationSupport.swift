import Foundation

enum FormValidationSupport {
    nonisolated static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func digitsOnly(_ value: String, maxLength: Int? = nil) -> String {
        let filtered = value.filter(\.isNumber)
        guard let maxLength else { return filtered }
        return String(filtered.prefix(maxLength))
    }

    nonisolated static func hasText(_ value: String) -> Bool {
        !trimmed(value).isEmpty
    }

    nonisolated static func requireText(_ value: String, message: String) -> String? {
        hasText(value) ? nil : message
    }

    nonisolated static func requireLength(
        _ value: String,
        max: Int,
        message: String
    ) -> String? {
        trimmed(value).count <= max ? nil : message
    }

    nonisolated static func parsePositiveAmount(
        _ value: String,
        max: Double,
        message: String
    ) -> Double? {
        guard let amount = Double(trimmed(value)), amount > 0, amount <= max else {
            return nil
        }
        return amount
    }

    nonisolated static func requireOneFilled(
        _ values: [String],
        message: String
    ) -> String? {
        values.contains(where: hasText) ? nil : message
    }
}
