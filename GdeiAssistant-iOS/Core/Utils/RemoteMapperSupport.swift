import Foundation

/// 兼容后端字符串、数字、布尔等混合返回，避免 DTO 解码过于脆弱。
struct RemoteFlexibleString: Decodable, Hashable {
    let rawValue: String

    nonisolated init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            rawValue = ""
            return
        }

        if let stringValue = try? container.decode(String.self) {
            rawValue = stringValue
            return
        }

        if let intValue = try? container.decode(Int.self) {
            rawValue = String(intValue)
            return
        }

        if let doubleValue = try? container.decode(Double.self) {
            if floor(doubleValue) == doubleValue {
                rawValue = String(Int(doubleValue))
            } else {
                rawValue = String(doubleValue)
            }
            return
        }

        if let boolValue = try? container.decode(Bool.self) {
            rawValue = boolValue ? "true" : "false"
            return
        }

        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "不支持的混合类型"
            )
        )
    }
}

enum RemoteMapperSupport {
    nonisolated static func text(_ value: RemoteFlexibleString?, fallback: String = "") -> String {
        let trimmed = value?.rawValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }

    nonisolated static func sanitizedText(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    nonisolated static func sanitizedTextList(_ values: [String]?) -> [String] {
        values?.compactMap { sanitizedText($0) } ?? []
    }

    nonisolated static func url(from value: String?) -> URL? {
        guard let sanitized = sanitizedText(value), let url = URL(string: sanitized) else {
            return nil
        }
        return url
    }

    nonisolated static func int(_ value: RemoteFlexibleString?, fallback: Int = 0) -> Int {
        let raw = text(value)
        guard !raw.isEmpty else { return fallback }

        if let intValue = Int(raw) {
            return intValue
        }

        if let doubleValue = Double(raw) {
            return Int(doubleValue)
        }

        return fallback
    }

    nonisolated static func double(_ value: RemoteFlexibleString?, fallback: Double = 0) -> Double {
        let raw = text(value)
        guard !raw.isEmpty else { return fallback }

        let pattern = #"-?\d+(\.\d+)?"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..<raw.endIndex, in: raw)),
            let range = Range(match.range, in: raw)
        else {
            return fallback
        }

        return Double(raw[range]) ?? fallback
    }

    nonisolated static func dateText(_ value: RemoteFlexibleString?, fallback: String = "") -> String {
        let raw = text(value)
        guard !raw.isEmpty else { return fallback }

        if raw.range(of: #"^\d{10,13}$"#, options: .regularExpression) != nil,
           let timestamp = Double(raw) {
            let seconds = raw.count == 13 ? timestamp / 1000 : timestamp
            let date = Date(timeIntervalSince1970: seconds)
            let formatter = DateFormatter()
            formatter.locale = AppLanguage.locale(for: UserPreferences.currentLocale)
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.string(from: date)
        }

        return raw
    }

    nonisolated static func firstNonEmpty(_ values: String?...) -> String {
        values
            .compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return trimmed.isEmpty ? nil : trimmed
            }
            .first ?? ""
    }

    nonisolated static func truncated(_ value: String, limit: Int) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit)) + "..."
    }
}
