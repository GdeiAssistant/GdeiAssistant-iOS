import Foundation
import UIKit

@MainActor
struct RequestBuilder {
    let environment: AppEnvironment
    let tokenProvider: @MainActor () -> String?

    func build(from request: APIRequest) throws -> URLRequest {
        let normalizedPath = request.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var url = environment.baseURL
        if !normalizedPath.isEmpty {
            url.append(path: normalizedPath)
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        urlRequest.setValue(AppConstants.API.jsonMimeType, forHTTPHeaderField: AppConstants.API.acceptHeader)
        urlRequest.setValue(environment.clientType, forHTTPHeaderField: AppConstants.API.clientTypeHeader)

        if request.body != nil, let contentType = request.contentType {
            urlRequest.setValue(contentType, forHTTPHeaderField: AppConstants.API.contentTypeHeader)
        }

        if request.requiresAuth, let token = tokenProvider(), !token.isEmpty {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: AppConstants.API.authorizationHeader)
        }

        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            urlRequest.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        }

        let locale = AppLanguage.currentIdentifier()
        urlRequest.setValue(locale, forHTTPHeaderField: "Accept-Language")

        urlRequest.setValue(RequestID.generate(), forHTTPHeaderField: "X-Request-ID")

        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        return urlRequest
    }
}
