import XCTest
@testable import GdeiAssistant_iOS

@MainActor
private enum RequestBuilderTestContext {
    static let environment: AppEnvironment = {
        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: false,
            clientType: "IOS"
        )
        environment.baseURL = URL(string: "https://example.com/api")!
        return environment
    }()
}

@MainActor
final class RequestBuilderTests: XCTestCase {
    func testBuildNormalizesPathAndAppliesDefaultHeaders() throws {
        let builder = RequestBuilder(environment: RequestBuilderTestContext.environment, tokenProvider: { "token-123" })
        let request = APIRequest.post(
            path: "/secret/list/",
            rawBody: Data("{}".utf8),
            contentType: AppConstants.API.jsonMimeType,
            queryItems: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "keyword", value: "tree hole")
            ],
            headers: ["X-Trace-ID": "trace-1"]
        )

        let urlRequest = try builder.build(from: request)

        XCTAssertEqual(
            urlRequest.url?.absoluteString,
            "https://example.com/api/secret/list?page=1&keyword=tree%20hole"
        )
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: AppConstants.API.acceptHeader), AppConstants.API.jsonMimeType)
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: AppConstants.API.contentTypeHeader), AppConstants.API.jsonMimeType)
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: AppConstants.API.clientTypeHeader), "IOS")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: AppConstants.API.authorizationHeader), "Bearer token-123")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "X-Trace-ID"), "trace-1")
        XCTAssertEqual(urlRequest.httpBody, Data("{}".utf8))
    }

    func testBuildSkipsAuthorizationWhenRequestDoesNotRequireAuth() throws {
        let builder = RequestBuilder(environment: RequestBuilderTestContext.environment, tokenProvider: { "token-123" })
        let request = APIRequest.get(path: "announcement/start/0/size/20", requiresAuth: false)

        let urlRequest = try builder.build(from: request)

        XCTAssertNil(urlRequest.value(forHTTPHeaderField: AppConstants.API.authorizationHeader))
        XCTAssertNil(urlRequest.value(forHTTPHeaderField: AppConstants.API.contentTypeHeader))
    }
}
