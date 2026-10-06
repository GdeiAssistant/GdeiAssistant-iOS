import CryptoKit
import Foundation

enum SocialChatImageSupport {
    nonisolated static let maxBytes = 5 * 1024 * 1024
    nonisolated static let allowedContentTypes: Set<String> = ["image/jpeg", "image/png"]

    /// Exact relative API path for authenticated DM images (no query, no token).
    nonisolated static func isExactChatImageAPIPath(_ path: String) -> Bool {
        SocialChatImageURL.isExactAPIPath(path)
    }

    nonisolated static func isAllowedContentType(_ raw: String?) -> Bool {
        guard let raw = RemoteMapperSupport.sanitizedText(raw)?.lowercased() else { return false }
        return allowedContentTypes.contains(raw)
    }

    nonisolated static func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

enum SocialDisplayTime {
    /// Format server ISO-8601 for list/bubble; keep original text when unparseable (never invent).
    nonisolated static func format(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return raw }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: trimmed)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: trimmed)
        }
        guard let date else { return trimmed }

        let calendar = Calendar.current
        let display = DateFormatter()
        display.locale = Locale.current
        if calendar.isDateInToday(date) {
            display.dateStyle = .none
            display.timeStyle = .short
        } else if calendar.isDateInYesterday(date) {
            display.dateStyle = .medium
            display.timeStyle = .short
            display.doesRelativeDateFormatting = true
        } else {
            display.dateStyle = .medium
            display.timeStyle = .short
        }
        return display.string(from: date)
    }
}
