import XCTest
@testable import GdeiAssistant_iOS

// MARK: - URL tracking URLProtocol

private final class LostFoundTrackingURLProtocol: URLProtocol {
    static var requestedPaths: [String] = []
    static var responseStub: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        LostFoundTrackingURLProtocol.requestedPaths.append(request.url?.path ?? "")

        guard let stub = LostFoundTrackingURLProtocol.responseStub else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        let (response, data) = stub(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Helpers

private func makeOKResponse(for request: URLRequest, body: String) -> (HTTPURLResponse, Data) {
    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    return (response, Data(body.utf8))
}

// MARK: - Tests

@MainActor
final class RemoteLostFoundRepositoryTests: XCTestCase {
    private var repository: RemoteLostFoundRepository!

    override func setUp() async throws {
        LostFoundTrackingURLProtocol.requestedPaths = []

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [LostFoundTrackingURLProtocol.self]
        let session = URLSession(configuration: config)

        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: false,
            clientType: "IOS"
        )
        environment.baseURL = URL(string: "https://test.example.com")!

        let apiClient = APIClient(
            environment: environment,
            session: session,
            tokenProvider: { nil },
            onUnauthorized: {}
        )
        repository = RemoteLostFoundRepository(apiClient: apiClient)
    }

    override func tearDown() async throws {
        LostFoundTrackingURLProtocol.requestedPaths = []
        LostFoundTrackingURLProtocol.responseStub = nil
        repository = nil
    }

    // MARK: - List-level tests

    func testFetchItemsDoesNotCallPreviewEndpoint() async throws {
        LostFoundTrackingURLProtocol.responseStub = { request in
            makeOKResponse(for: request, body: #"{"code":200,"success":true,"message":"","data":[]}"#)
        }

        _ = try await repository.fetchItems()

        XCTAssertFalse(
            LostFoundTrackingURLProtocol.requestedPaths.contains { $0.contains("preview") },
            "fetchItems() should not call any /preview endpoint"
        )
    }

    func testFetchItemsMakesExactlyTwoRequestsToListEndpoints() async throws {
        LostFoundTrackingURLProtocol.responseStub = { request in
            makeOKResponse(for: request, body: #"{"code":200,"success":true,"message":"","data":[]}"#)
        }

        _ = try await repository.fetchItems()

        XCTAssertEqual(
            LostFoundTrackingURLProtocol.requestedPaths.count, 2,
            "Expected exactly 2 list requests, got: \(LostFoundTrackingURLProtocol.requestedPaths)"
        )
        XCTAssertTrue(
            LostFoundTrackingURLProtocol.requestedPaths.contains { $0.contains("/lostandfound/lostitem/start/0") },
            "Expected lost-item list request"
        )
        XCTAssertTrue(
            LostFoundTrackingURLProtocol.requestedPaths.contains { $0.contains("/lostandfound/founditem/start/0") },
            "Expected found-item list request"
        )
    }

    // MARK: - Detail-level fallback tests

    func testFetchDetailWithImagesDoesNotCallPreviewFallback() async throws {
        // Detail DTO with a non-empty pictureURL → imageURLs non-empty → no preview call
        let detailJSON = #"""
        {
          "code": 200, "success": true, "message": "", "data": {
            "item": {
              "id": 42, "name": "手机", "state": 0,
              "pictureURL": ["https://cdn.example.com/img.jpg"]
            },
            "profile": null
          }
        }
        """#

        LostFoundTrackingURLProtocol.responseStub = { request in
            makeOKResponse(for: request, body: detailJSON)
        }

        _ = try await repository.fetchDetail(itemID: "42")

        XCTAssertFalse(
            LostFoundTrackingURLProtocol.requestedPaths.contains { $0.contains("preview") },
            "fetchDetail() should not call /preview when detail already has images"
        )
    }

    func testFetchDetailWithoutImagesCallsPreviewFallback() async throws {
        // Detail DTO with null pictureURL → imageURLs empty → preview fallback fires
        let detailJSON = #"""
        {
          "code": 200, "success": true, "message": "", "data": {
            "item": {
              "id": 99, "name": "钥匙", "state": 0,
              "pictureURL": null
            },
            "profile": null
          }
        }
        """#
        let previewJSON = #"{"code":200,"success":true,"message":"","data":"https://cdn.example.com/preview.jpg"}"#

        LostFoundTrackingURLProtocol.responseStub = { request in
            let path = request.url?.path ?? ""
            if path.contains("preview") {
                return makeOKResponse(for: request, body: previewJSON)
            }
            return makeOKResponse(for: request, body: detailJSON)
        }

        _ = try await repository.fetchDetail(itemID: "99")

        XCTAssertTrue(
            LostFoundTrackingURLProtocol.requestedPaths.contains { $0.contains("preview") },
            "fetchDetail() should call /preview fallback when detail has no images"
        )
    }
}
