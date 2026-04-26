import Foundation

enum SensitiveValueMasker {
    nonisolated static func maskPhone(_ phone: String?) -> String {
        let normalized = phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalized.isEmpty else { return "" }
        if normalized.contains("*") { return normalized }

        if normalized.count >= 11 {
            return "\(normalized.prefix(3))****\(normalized.suffix(4))"
        }
        if normalized.count > 4 {
            return "\(normalized.prefix(2))***\(normalized.suffix(2))"
        }
        return normalized
    }

    nonisolated static func maskEmail(_ email: String?) -> String {
        let normalized = email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalized.isEmpty else { return "" }
        if normalized.contains("***@") { return normalized }

        let parts = normalized.split(separator: "@", maxSplits: 1)
        guard parts.count == 2 else { return normalized }

        let local = String(parts[0])
        let domain = String(parts[1])
        return "\(local.prefix(3))***@\(domain)"
    }

    nonisolated static func maskCampusAccount(_ account: String?) -> String {
        let normalized = account?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalized.isEmpty else { return "" }
        if normalized.contains("*") { return normalized }

        if normalized.count >= 8 {
            return "\(normalized.prefix(2))****\(normalized.suffix(2))"
        }
        if normalized.count >= 3 {
            return "\(normalized.prefix(1))***\(normalized.suffix(1))"
        }
        if normalized.count >= 2 {
            return "\(normalized.prefix(1))***"
        }
        return "*"
    }

    nonisolated static func maskTokenOrSession(_ value: String?) -> String {
        let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalized.isEmpty else { return "" }
        if normalized.contains("*") { return normalized }

        if normalized.count >= 12 {
            return "\(normalized.prefix(4))****\(normalized.suffix(4))"
        }
        if normalized.count > 4 {
            return "\(normalized.prefix(2))***\(normalized.suffix(2))"
        }
        return "***"
    }
}
