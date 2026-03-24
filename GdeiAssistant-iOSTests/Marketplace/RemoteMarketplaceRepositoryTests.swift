import XCTest
@testable import GdeiAssistant_iOS

// MARK: - URL tracking URLProtocol

private final class RepositoryTrackingURLProtocol: URLProtocol {
    static var requestedPaths: [String] = []
    static var responseStub: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        RepositoryTrackingURLProtocol.requestedPaths.append(request.url?.path ?? "")

        guard let stub = RepositoryTrackingURLProtocol.responseStub else {
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

// MARK: - Tests

@MainActor
final class RemoteMarketplaceRepositoryTests: XCTestCase {
    private var repository: RemoteMarketplaceRepository!

    override func setUp() async throws {
        RepositoryTrackingURLProtocol.requestedPaths = []
        RepositoryTrackingURLProtocol.responseStub = { request in
            let body = Data(#"{"code":200,"success":true,"message":"","data":[]}"#.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RepositoryTrackingURLProtocol.self]
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
        repository = RemoteMarketplaceRepository(apiClient: apiClient)
    }

    override func tearDown() async throws {
        RepositoryTrackingURLProtocol.requestedPaths = []
        RepositoryTrackingURLProtocol.responseStub = nil
        repository = nil
    }

    func testFetchItemsDoesNotCallPreviewEndpoint() async throws {
        _ = try await repository.fetchItems(typeID: nil)

        XCTAssertFalse(
            RepositoryTrackingURLProtocol.requestedPaths.contains { $0.contains("preview") },
            "fetchItems should not call any /preview endpoint"
        )
    }

    func testFetchItemsByTypeDoesNotCallPreviewEndpoint() async throws {
        _ = try await repository.fetchItems(typeID: 3)

        XCTAssertFalse(
            RepositoryTrackingURLProtocol.requestedPaths.contains { $0.contains("preview") },
            "fetchItems(typeID:) should not call any /preview endpoint"
        )
    }

    func testSearchItemsDoesNotCallPreviewEndpoint() async throws {
        _ = try await repository.searchItems(keyword: "书", start: 0)

        XCTAssertFalse(
            RepositoryTrackingURLProtocol.requestedPaths.contains { $0.contains("preview") },
            "searchItems should not call any /preview endpoint"
        )
    }

    func testFetchItemsMakesExactlyOneRequest() async throws {
        _ = try await repository.fetchItems(typeID: nil)

        XCTAssertEqual(RepositoryTrackingURLProtocol.requestedPaths.count, 1)
        XCTAssertTrue(
            RepositoryTrackingURLProtocol.requestedPaths[0].contains("/ershou/item/start/0"),
            "Expected list endpoint, got: \(RepositoryTrackingURLProtocol.requestedPaths)"
        )
    }
}
