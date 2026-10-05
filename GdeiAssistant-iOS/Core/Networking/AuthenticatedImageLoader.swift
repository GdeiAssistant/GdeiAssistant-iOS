import Foundation
import UIKit

/// Loads remote images using the shared URLSession + RequestBuilder auth path.
/// Relative `/api/...` or same-host absolute API URLs include Bearer; tokens never go in query.
@MainActor
final class AuthenticatedImageLoader {
    private let environment: AppEnvironment
    private let session: URLSession
    private let requestBuilder: RequestBuilder
    private let onUnauthorized: () -> Void
    private let tokenProvider: @MainActor () -> String?
    private var memoryCache: [String: UIImage] = [:]
    private var cacheToken: String?
    private var cacheGeneration: UInt64 = 0

    init(
        environment: AppEnvironment,
        session: URLSession,
        tokenProvider: @escaping @MainActor () -> String?,
        onUnauthorized: @escaping () -> Void
    ) {
        self.environment = environment
        self.session = session
        self.tokenProvider = tokenProvider
        self.requestBuilder = RequestBuilder(environment: environment, tokenProvider: tokenProvider)
        self.onUnauthorized = onUnauthorized
    }

    func image(for urlString: String?) async -> UIImage? {
        await load(urlString: urlString, chatImageOnly: false)
    }

    /// DM chat images: Bearer only on exact same-origin chat-image path; never public/AsyncImage.
    func chatImage(for urlString: String?) async -> UIImage? {
        await load(urlString: urlString, chatImageOnly: true)
    }

    private func load(urlString: String?, chatImageOnly: Bool) async -> UIImage? {
        let currentToken = tokenProvider()
        if cacheToken != currentToken {
            clearCache()
            cacheToken = currentToken
        }
        let generation = cacheGeneration
        guard let raw = RemoteMapperSupport.sanitizedText(urlString) else {
            return nil
        }
        let source: ResolvedSource
        if chatImageOnly {
            guard let path = SocialChatImageURL.relativePath(for: raw, baseURL: environment.baseURL),
                  let currentToken, !currentToken.isEmpty else { return nil }
            source = .authenticatedPath(path)
        } else {
            source = resolve(raw)
        }
        // Validate private URLs before consulting the general avatar/image cache.
        if let cached = memoryCache[raw] {
            return cached
        }

        switch source {
        case .none:
            return nil
        case .publicURL(let url):
            if chatImageOnly {
                // Private DM images must not load as naked public URLs.
                return nil
            }
            do {
                let (data, response) = try await session.data(from: url)
                guard generation == cacheGeneration, currentToken == tokenProvider() else {
                    return nil
                }
                guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode),
                      let image = UIImage(data: data) else {
                    return nil
                }
                memoryCache[raw] = image
                return image
            } catch {
                return nil
            }
        case .authenticatedPath(let path):
            if chatImageOnly, !SocialChatImageSupport.isExactChatImageAPIPath(path) {
                return nil
            }
            do {
                let request = APIRequest.get(path: path, requiresAuth: true)
                var urlRequest = try requestBuilder.build(from: request)
                urlRequest.setValue("image/*,*/*", forHTTPHeaderField: AppConstants.API.acceptHeader)
                if chatImageOnly {
                    urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
                }
                let (data, response) = try await session.data(for: urlRequest)
                guard generation == cacheGeneration, currentToken == tokenProvider() else {
                    return nil
                }
                guard let http = response as? HTTPURLResponse else {
                    return nil
                }
                if http.statusCode == 401 {
                    onUnauthorized()
                    return nil
                }
                guard (200 ... 299).contains(http.statusCode),
                      !chatImageOnly || (data.count <= SocialChatImageSupport.maxBytes
                        && SocialChatImageSupport.isAllowedContentType(http.mimeType)),
                      let image = UIImage(data: data) else {
                    return nil
                }
                memoryCache[raw] = image
                return image
            } catch {
                return nil
            }
        }
    }

    func clearCache() {
        memoryCache.removeAll()
        cacheToken = nil
        cacheGeneration &+= 1
    }

    enum ResolvedSource {
        case none
        case publicURL(URL)
        case authenticatedPath(String)
    }

    func resolve(_ urlString: String) -> ResolvedSource {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }

        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() {
            guard (scheme == "http" || scheme == "https"), url.user == nil, url.password == nil else {
                return .none
            }
            let baseURL = environment.baseURL
            let port = url.port ?? (scheme == "https" ? 443 : 80)
            let baseScheme = baseURL.scheme?.lowercased()
            let basePort = baseURL.port ?? (baseScheme == "https" ? 443 : 80)
            if url.host?.lowercased() == baseURL.host?.lowercased(),
               scheme == baseScheme, port == basePort {
                if let path = apiRelativePath(fromAbsolutePath: url.path) {
                    return .authenticatedPath(path)
                }
            }
            return .publicURL(url)
        }

        if !trimmed.hasPrefix("//"), let path = apiRelativePath(fromRelative: trimmed) {
            return .authenticatedPath(path)
        }
        return .none
    }

    private func apiRelativePath(fromAbsolutePath path: String) -> String? {
        let basePath = environment.baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var remainder = path
        if !basePath.isEmpty {
            let prefix = "/" + basePath
            if remainder.hasPrefix(prefix + "/") {
                remainder = String(remainder.dropFirst(prefix.count + 1))
            } else if remainder == prefix {
                return nil
            } else if remainder.hasPrefix("/api/") {
                remainder = String(remainder.dropFirst(5))
            }
        } else if remainder.hasPrefix("/api/") {
            remainder = String(remainder.dropFirst(5))
        }
        let normalized = remainder.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized.isEmpty ? nil : normalized
    }

    private func apiRelativePath(fromRelative raw: String) -> String? {
        var path = raw
        if path.hasPrefix("/api/") {
            path = String(path.dropFirst(5))
        } else if path.hasPrefix("api/") {
            path = String(path.dropFirst(4))
        }
        let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return normalized.isEmpty ? nil : normalized
    }
}
