import XCTest
@testable import GdeiAssistant_iOS

private final class ChargeRepositoryURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        guard let handler = Self.handler else {
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

final class ChargeRemoteMapperTests: XCTestCase {
    func testChargeFormFieldsDoNotIncludeLegacyHmacFields() {
        let fields = ChargeRemoteMapper.chargeFormFields(
            amount: 50,
            password: "synthetic-charge-password"
        )
        let fieldNames = Set(fields.map(\.name))
        let valuesByName = Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0.value) })

        XCTAssertEqual(fieldNames, ["amount", "password"])
        XCTAssertEqual(valuesByName["amount"], "50")
        XCTAssertEqual(valuesByName["password"], "synthetic-charge-password")
        XCTAssertFalse(fieldNames.contains("hmac"))
        XCTAssertFalse(fieldNames.contains("timestamp"))
    }
}

@MainActor
final class RemoteChargeRepositoryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ChargeRepositoryURLProtocol.handler = nil
        ChargeRepositoryURLProtocol.requests = []
    }

    override func tearDown() {
        ChargeRepositoryURLProtocol.handler = nil
        ChargeRepositoryURLProtocol.requests = []
        super.tearDown()
    }

    func testSubmitChargeSendsIdempotencyKeyHeader() async throws {
        let repository = makeRepository(keys: ["synthetic-charge-key-1"])
        stubSuccessfulChargeResponse()

        let payment = try await repository.submitCharge(
            amount: 50,
            password: "synthetic-charge-password"
        )

        XCTAssertEqual(payment.alipayURL, "https://pay.example.test/charge")
        XCTAssertEqual(ChargeRepositoryURLProtocol.requests.count, 1)
        let request = try XCTUnwrap(ChargeRepositoryURLProtocol.requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Idempotency-Key"), "synthetic-charge-key-1")
    }

    func testSubmitChargeGeneratesNewKeyForNewUserAttempts() async throws {
        let repository = makeRepository(keys: [
            "synthetic-charge-key-1",
            "synthetic-charge-key-2"
        ])
        stubSuccessfulChargeResponse()

        _ = try await repository.submitCharge(amount: 50, password: "synthetic-charge-password")
        _ = try await repository.submitCharge(amount: 50, password: "synthetic-charge-password")

        let sentKeys = ChargeRepositoryURLProtocol.requests.map {
            $0.value(forHTTPHeaderField: "Idempotency-Key")
        }
        XCTAssertEqual(sentKeys, [
            "synthetic-charge-key-1",
            "synthetic-charge-key-2"
        ])
    }

    private func makeRepository(keys: [String]) -> RemoteChargeRepository {
        var generatedKeys = keys
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ChargeRepositoryURLProtocol.self]
        let session = URLSession(configuration: config)

        let environment = AppEnvironment(
            networkEnvironment: .prod,
            dataSourceMode: .remote,
            isDebug: false,
            clientType: "IOS"
        )
        environment.baseURL = URL(string: "https://test.example.com/api")!

        let client = APIClient(
            environment: environment,
            session: session,
            tokenProvider: { "synthetic-token" },
            onUnauthorized: {}
        )
        return RemoteChargeRepository(
            apiClient: client,
            idempotencyKeyGenerator: ChargeIdempotencyKeyGenerator(
                makeKey: { generatedKeys.removeFirst() }
            )
        )
    }

    private func stubSuccessfulChargeResponse() {
        let responseBody = Data(
            #"""
            {"code":200,"success":true,"message":"","data":{"alipayURL":"https://pay.example.test/charge","cookieList":[]}}
            """#.utf8
        )
        ChargeRepositoryURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseBody)
        }
    }
}
