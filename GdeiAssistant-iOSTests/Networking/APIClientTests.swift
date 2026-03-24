import XCTest
@testable import GdeiAssistant_iOS

// MARK: - URLProtocol stub

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Tests

@MainActor
final class APIClientTests: XCTestCase {
    private var client: APIClient!
    private var unauthorizedCallCount = 0

    override func setUp() async throws {
        unauthorizedCallCount = 0

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: false,
            clientType: "IOS"
        )
        environment.baseURL = URL(string: "https://test.example.com")!

        client = APIClient(
            environment: environment,
            session: session,
            tokenProvider: { "test-token" },
            onUnauthorized: { [weak self] in self?.unauthorizedCallCount += 1 }
        )
    }

    override func tearDown() async throws {
        MockURLProtocol.handler = nil
        client = nil
    }

    // MARK: - Helpers

    private func stub(statusCode: Int, body: String, headers: [String: String] = [:]) {
        let bodyData = Data(body.utf8)
        MockURLProtocol.handler = { [bodyData] request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!
            return (response, bodyData)
        }
    }

    // MARK: - Tests

    func testSuccessResponseDecodesPayload() async throws {
        struct Payload: Codable { let name: String }
        stub(statusCode: 200, body: #"{"code":200,"success":true,"message":"","data":{"name":"张三"}}"#)

        let result: Payload = try await client.get("/user/name")
        XCTAssertEqual(result.name, "张三")
    }

    func testHTTP401ThrowsUnauthorizedAndCallsHandler() async throws {
        stub(statusCode: 401, body: "")

        do {
            let _: EmptyPayload = try await client.get("/protected")
            XCTFail("Expected NetworkError.unauthorized")
        } catch NetworkError.unauthorized {
            XCTAssertEqual(unauthorizedCallCount, 1)
        }
    }

    func testNon2xxThrowsHTTPStatusWithMessage() async throws {
        stub(statusCode: 403, body: #"{"code":403,"message":"无权访问","success":false}"#)

        do {
            let _: EmptyPayload = try await client.get("/admin")
            XCTFail("Expected NetworkError.httpStatus")
        } catch NetworkError.httpStatus(let code, let message) {
            XCTAssertEqual(code, 403)
            XCTAssertEqual(message, "无权访问")
        }
    }

    func testServerBusinessFailureThrowsServerError() async throws {
        stub(statusCode: 200, body: #"{"code":10001,"message":"商品已下架","success":false}"#)

        do {
            let _: EmptyPayload = try await client.get("/ershou/item/id/1")
            XCTFail("Expected NetworkError.server")
        } catch NetworkError.server(let code, let message) {
            XCTAssertEqual(code, 10001)
            XCTAssertEqual(message, "商品已下架")
        }
    }

    func testMalformedJSONThrowsDecoding() async throws {
        stub(statusCode: 200, body: "not-json")

        do {
            let _: EmptyPayload = try await client.get("/broken")
            XCTFail("Expected NetworkError.decoding")
        } catch NetworkError.decoding {
            // expected
        }
    }
}
