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

/// 兼容后端数字或数字字符串返回，直接解码为数值。
struct RemoteFlexibleDouble: Decodable, Hashable, Sendable {
    let rawValue: Double?

    nonisolated init(_ rawValue: Double?) {
        self.rawValue = rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            rawValue = nil
            return
        }

        if let doubleValue = try? container.decode(Double.self) {
            rawValue = doubleValue
            return
        }

        if let intValue = try? container.decode(Int.self) {
            rawValue = Double(intValue)
            return
        }

        if let stringValue = try? container.decode(String.self) {
            let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                rawValue = nil
                return
            }
            if let direct = Double(trimmed) {
                rawValue = direct
                return
            }
            if let extracted = RemoteMapperSupport.extractFirstDouble(in: trimmed) {
                rawValue = extracted
                return
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "无法解析的数值字符串"
            )
        }

        throw DecodingError.typeMismatch(
            Double.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "不支持的数值类型"
            )
        )
    }
}

private nonisolated final class TimestampDateFormatterCache: @unchecked Sendable {
    private let lock = NSLock()
    private var formatters: [String: DateFormatter] = [:]

    init() {}

    func string(from date: Date, locale: Locale) -> String {
        let key = locale.identifier
        lock.lock()
        defer { lock.unlock() }
        let formatter: DateFormatter
        if let cached = formatters[key] {
            formatter = cached
        } else {
            let created = DateFormatter()
            created.locale = locale
            created.timeZone = TimeZone(identifier: "Asia/Shanghai")
            created.dateFormat = "yyyy-MM-dd HH:mm"
            formatters[key] = created
            formatter = created
        }
        return formatter.string(from: date)
    }
}

enum RemoteMapperSupport {
    private nonisolated static let numericRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"-?\d+(\.\d+)?"#
    )

    private nonisolated static let timestampFormatterCache = TimestampDateFormatterCache()

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

    nonisolated static func double(_ value: RemoteFlexibleDouble?, fallback: Double = 0) -> Double {
        value?.rawValue ?? fallback
    }

    nonisolated static func double(_ value: RemoteFlexibleString?, fallback: Double = 0) -> Double {
        let raw = text(value)
        guard !raw.isEmpty else { return fallback }

        if let direct = Double(raw) {
            return direct
        }

        return extractFirstDouble(in: raw) ?? fallback
    }

    nonisolated static func extractFirstDouble(in raw: String) -> Double? {
        guard
            let regex = numericRegex,
            let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..<raw.endIndex, in: raw)),
            let range = Range(match.range, in: raw)
        else {
            return nil
        }

        return Double(raw[range])
    }

    nonisolated static func dateText(_ value: RemoteFlexibleString?, fallback: String = "") -> String {
        let raw = text(value)
        guard !raw.isEmpty else { return fallback }

        if (10...13).contains(raw.count),
           raw.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }),
           let timestamp = Double(raw) {
            let seconds = raw.count == 13 ? timestamp / 1000 : timestamp
            let date = Date(timeIntervalSince1970: seconds)
            let locale = AppLanguage.locale(for: UserPreferences.currentLocale)
            return timestampFormatterCache.string(from: date, locale: locale)
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
