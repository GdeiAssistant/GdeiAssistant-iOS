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
    private var savedLocale: Any?

    override func setUp() async throws {
        savedLocale = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.selectedLocale)
        UserDefaults.standard.set("zh-CN", forKey: AppConstants.UserDefaultsKeys.selectedLocale)
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
        if let savedLocale { UserDefaults.standard.set(savedLocale, forKey: AppConstants.UserDefaultsKeys.selectedLocale) }
        else { UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.selectedLocale) }
        savedLocale = nil
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
            RepositoryTrackingURLProtocol.requestedPaths[0].contains("/marketplace/item/start/0"),
            "Expected list endpoint, got: \(RepositoryTrackingURLProtocol.requestedPaths)"
        )
    }

    func testMarketplaceRemoteMapperUsesLocalizedCatalogForTypeNames() {
        UserDefaults.standard.set("en-US", forKey: AppConstants.UserDefaultsKeys.selectedLocale)

        XCTAssertEqual(
            MarketplaceRemoteMapper.displayName(forType: 0),
            "Campus Transportation"
        )
    }

    func testMarketplaceRemoteMapperUsesLocalizedFallbacksForPersonalSummary() {
        UserDefaults.standard.set("en-US", forKey: AppConstants.UserDefaultsKeys.selectedLocale)

        let summary = MarketplaceRemoteMapper.mapPersonalSummary(
            MarketplacePersonalSummaryDTO(doing: nil, sold: nil, off: nil),
            profile: UserProfileDTO(
                username: "",
                nickname: nil,
                avatar: nil,
                facultyCode: nil,
                majorCode: nil,
                enrollment: nil,
                location: nil,
                hometown: nil,
                introduction: nil,
                birthday: nil,
                ipArea: nil,
                age: nil
            )
        )

        XCTAssertEqual(summary.nickname, "Marketplace User")
        XCTAssertEqual(summary.introduction, "This person is lazy and left nothing here.")
    }
    func testMappedMarketplaceTypeFollowsAllLocalesAndKeepsUnknownTagsAndUserText() throws {
        let dto = try JSONDecoder().decode(MarketplaceDetailDTO.self, from: Data(#"{"item":{"id":1,"name":"校园代步","description":"用户写的校园代步","type":0,"state":1}}"#.utf8))
        let detail = try MarketplaceRemoteMapper.mapDetail(dto)
        XCTAssertEqual(detail.item.typeID, 0)
        let legacyData = try JSONEncoder().encode(detail.item)
        var legacy = detail.item
        legacy.typeID = nil
        var unknown = detail.item
        unknown.typeID = 999
        for language in AppLanguage.allCases {
            let locale = language.localeIdentifier
            UserDefaults.standard.set(locale, forKey: AppConstants.UserDefaultsKeys.selectedLocale)
            let expected = LocalizedProfileCatalog.current.defaultOptions.marketplaceItemTypes.first(where: { $0.code == 0 })?.label
            XCTAssertEqual(detail.item.typeDisplayName(), expected)
            XCTAssertEqual(detail.categoryDisplayName(), expected)
            XCTAssertEqual(detail.item.displayTags(), [expected ?? ""])
            XCTAssertEqual(legacy.displayTags(), detail.item.tags)
            XCTAssertEqual(unknown.displayTags(), detail.item.tags)
            XCTAssertEqual(detail.item.title, "校园代步")
            XCTAssertEqual(detail.description, "用户写的校园代步")
        }
        XCTAssertEqual(try JSONDecoder().decode(MarketplaceItem.self, from: legacyData).typeID, 0)
        let old = try JSONSerialization.jsonObject(with: legacyData) as? [String: Any]
        var withoutType = try XCTUnwrap(old)
        withoutType.removeValue(forKey: "typeID")
        let decodedOld = try JSONDecoder().decode(MarketplaceItem.self, from: JSONSerialization.data(withJSONObject: withoutType))
        XCTAssertNil(decodedOld.typeID)
        XCTAssertEqual(decodedOld.tags, detail.item.tags)
    }

}
