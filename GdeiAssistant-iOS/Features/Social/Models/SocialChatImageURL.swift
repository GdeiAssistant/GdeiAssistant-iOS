import Foundation

/// The only URL shape that may carry credentials for private message images.
enum SocialChatImageURL {
    nonisolated static func isExactAPIPath(_ path: String) -> Bool {
        path.range(
            of: #"^social/conversations/[0-9]+/messages/[0-9]+/image\z"#,
            options: .regularExpression
        ) != nil
    }

    nonisolated static func relativePath(for raw: String, baseURL: URL) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              components.query == nil, components.fragment == nil,
              components.user == nil, components.password == nil,
              components.percentEncodedPath == components.path else { return nil }

        let basePath = baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let apiPrefix = basePath.isEmpty ? "/api/" : "/\(basePath)/"
        var path = components.path
        if let scheme = components.scheme?.lowercased() {
            let baseScheme = baseURL.scheme?.lowercased()
            guard scheme == "http" || scheme == "https",
                  scheme == baseScheme,
                  components.host?.lowercased() == baseURL.host?.lowercased(),
                  (components.port ?? (scheme == "https" ? 443 : 80))
                    == (baseURL.port ?? (baseScheme == "https" ? 443 : 80)),
                  path.hasPrefix(apiPrefix) else { return nil }
            path = String(path.dropFirst(apiPrefix.count))
        } else {
            guard components.host == nil, !trimmed.hasPrefix("//") else { return nil }
            if path.hasPrefix(apiPrefix) {
                path = String(path.dropFirst(apiPrefix.count))
            }
        }
        return isExactAPIPath(path) ? path : nil
    }
}
