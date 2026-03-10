import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
}

struct APIRequest {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: Data?
    let contentType: String?
    let requiresAuth: Bool

    static func get(
        path: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true,
        headers: [String: String] = [:]
    ) -> APIRequest {
        APIRequest(
            path: path,
            method: .get,
            queryItems: queryItems,
            headers: headers,
            body: nil,
            contentType: nil,
            requiresAuth: requiresAuth
        )
    }

    static func delete(
        path: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true,
        headers: [String: String] = [:]
    ) -> APIRequest {
        APIRequest(
            path: path,
            method: .delete,
            queryItems: queryItems,
            headers: headers,
            body: nil,
            contentType: nil,
            requiresAuth: requiresAuth
        )
    }

    static func post<Body: Encodable>(
        path: String,
        body: Body,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true,
        headers: [String: String] = [:],
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> APIRequest {
        let bodyData = try encoder.encode(body)

        return APIRequest(
            path: path,
            method: .post,
            queryItems: queryItems,
            headers: headers,
            body: bodyData,
            contentType: AppConstants.API.jsonMimeType,
            requiresAuth: requiresAuth
        )
    }

    static func post(
        path: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true,
        headers: [String: String] = [:]
    ) -> APIRequest {
        APIRequest(
            path: path,
            method: .post,
            queryItems: queryItems,
            headers: headers,
            body: nil,
            contentType: nil,
            requiresAuth: requiresAuth
        )
    }

    static func postForm(
        path: String,
        fields: [FormFieldValue],
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true,
        headers: [String: String] = [:]
    ) -> APIRequest {
        APIRequest(
            path: path,
            method: .post,
            queryItems: queryItems,
            headers: headers,
            body: FormURLEncoder.encode(fields: fields),
            contentType: AppConstants.API.formURLEncodedMimeType,
            requiresAuth: requiresAuth
        )
    }

    static func postMultipart(
        path: String,
        payload: MultipartFormDataPayload,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true,
        headers: [String: String] = [:]
    ) -> APIRequest {
        APIRequest(
            path: path,
            method: .post,
            queryItems: queryItems,
            headers: headers,
            body: payload.body,
            contentType: payload.contentType,
            requiresAuth: requiresAuth
        )
    }

    static func post(
        path: String,
        rawBody: Data,
        contentType: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true,
        headers: [String: String] = [:]
    ) -> APIRequest {
        APIRequest(
            path: path,
            method: .post,
            queryItems: queryItems,
            headers: headers,
            body: rawBody,
            contentType: contentType,
            requiresAuth: requiresAuth
        )
    }
}
