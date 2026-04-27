import Foundation
import OSLog

@MainActor
final class APIClient {
    typealias UnauthorizedHandler = @MainActor () -> Void

    private let session: URLSession
    private let requestBuilder: RequestBuilder
    private let onUnauthorized: UnauthorizedHandler
    private let decoder = JSONDecoder()

    init(
        environment: AppEnvironment,
        session: URLSession = .shared,
        tokenProvider: @escaping @MainActor () -> String?,
        onUnauthorized: @escaping UnauthorizedHandler
    ) {
        self.session = session
        self.requestBuilder = RequestBuilder(environment: environment, tokenProvider: tokenProvider)
        self.onUnauthorized = onUnauthorized
    }

    func get<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = APIRequest.get(path: path, queryItems: queryItems, requiresAuth: requiresAuth)
        return try await execute(request, responseType: T.self)
    }

    func post<Body: Encodable, T: Decodable>(
        _ path: String,
        body: Body,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = try APIRequest.post(path: path, body: body, queryItems: queryItems, requiresAuth: requiresAuth)
        return try await execute(request, responseType: T.self)
    }

    func post<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = APIRequest.post(path: path, queryItems: queryItems, requiresAuth: requiresAuth)
        return try await execute(request, responseType: T.self)
    }

    func postForm<T: Decodable>(
        _ path: String,
        fields: [FormFieldValue],
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true,
        headers: [String: String] = [:]
    ) async throws -> T {
        let request = APIRequest.postForm(
            path: path,
            fields: fields,
            queryItems: queryItems,
            requiresAuth: requiresAuth,
            headers: headers
        )
        return try await execute(request, responseType: T.self)
    }

    func postMultipart<T: Decodable>(
        _ path: String,
        fields: [FormFieldValue],
        files: [MultipartFormFile],
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> T {
        let payload = MultipartFormDataBuilder.build(fields: fields, files: files)
        let request = APIRequest.postMultipart(
            path: path,
            payload: payload,
            queryItems: queryItems,
            requiresAuth: requiresAuth
        )
        return try await execute(request, responseType: T.self)
    }

    func delete<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = APIRequest.delete(path: path, queryItems: queryItems, requiresAuth: requiresAuth)
        return try await execute(request, responseType: T.self)
    }

    private func execute<T: Decodable>(
        _ request: APIRequest,
        responseType: T.Type
    ) async throws -> T {
        let urlRequest = try requestBuilder.build(from: request)
        let requestId = urlRequest.value(forHTTPHeaderField: "X-Request-ID") ?? "?"
        let method = urlRequest.httpMethod ?? "?"
        let path = urlRequest.url?.path ?? "?"
        let start = Date()

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            let elapsed = Int(Date().timeIntervalSince(start) * 1000)
            AppLogger.network.warning("rid:\(requestId) | \(method) \(path) | FAILED | \(elapsed)ms | \(error.localizedDescription)")
            throw NetworkError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        let elapsed = Int(Date().timeIntervalSince(start) * 1000)
        let backendRid = httpResponse.value(forHTTPHeaderField: "X-Request-ID")
        if let backendRid {
            AppLogger.network.info("client-rid:\(requestId) backend-rid:\(backendRid) | \(method) \(path) | \(httpResponse.statusCode) | \(elapsed)ms")
        } else {
            AppLogger.network.info("rid:\(requestId) | \(method) \(path) | \(httpResponse.statusCode) | \(elapsed)ms")
        }

        if httpResponse.statusCode == 401 {
            onUnauthorized()
            throw NetworkError.unauthorized
        }

        if !(200 ... 299).contains(httpResponse.statusCode) {
            let message = parseErrorMessage(from: data)
            throw NetworkError.httpStatus(httpResponse.statusCode, message)
        }

        let apiResponse: APIResponse<T>
        do {
            apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }

        if !apiResponse.isSuccess {
            if AppConstants.API.unauthorizedBusinessCodes.contains(apiResponse.code) {
                onUnauthorized()
                throw NetworkError.unauthorized
            }
            throw NetworkError.server(code: apiResponse.code, message: apiResponse.message)
        }

        if let payload = apiResponse.data {
            return payload
        }

        if responseType == EmptyPayload.self {
            return EmptyPayload() as! T
        }

        throw NetworkError.noData
    }

    private func parseErrorMessage(from data: Data) -> String {
        if let response = try? decoder.decode(APIResponse<EmptyPayload>.self, from: data), !response.message.isEmpty {
            return response.message
        }

        return ""
    }
}
