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

    func testPaymentMapsReturnedOrderStatusWithoutFinalSettlementClaim() throws {
        let dto = try JSONDecoder().decode(
            ChargeResponseDTO.self,
            from: Data(
                #"""
                {
                  "alipayURL":"https://pay.example.test/charge",
                  "cookieList":[],
                  "orderId":"synthetic-order-id",
                  "status":"PAYMENT_SESSION_CREATED",
                  "message":"支付请求已生成，请完成支付并刷新余额。该状态不代表最终到账。",
                  "retryAfter":60
                }
                """#.utf8
            )
        )

        let payment = try XCTUnwrap(ChargeRemoteMapper.mapPayment(dto, amount: 50))

        XCTAssertEqual(payment.order?.orderId, "synthetic-order-id")
        XCTAssertEqual(payment.order?.amount, 50)
        XCTAssertEqual(payment.order?.normalizedStatus, "PAYMENT_SESSION_CREATED")
        XCTAssertFalse(localizedString("charge.order.status.paymentSessionCreated", locale: "zh-CN").contains("充值已到账"))
        XCTAssertFalse(localizedString("charge.order.status.paymentSessionCreated", locale: "zh-CN").contains("充值成功到账"))
        XCTAssertFalse(localizedString("charge.order.status.paymentSessionCreated", locale: "zh-CN").contains("余额已增加"))
    }

    func testProcessingAndUnknownMessagesDiscourageDuplicateSubmission() {
        XCTAssertTrue(localizedString("charge.order.status.processing", locale: "zh-CN").contains("避免重复提交"))
        XCTAssertTrue(localizedString("charge.order.status.unknown", locale: "zh-CN").contains("避免重复提交"))
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
        XCTAssertEqual(payment.order?.orderId, "synthetic-order-id")
        XCTAssertEqual(payment.order?.normalizedStatus, "PAYMENT_SESSION_CREATED")
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

    func testFetchChargeOrderParsesSafeFields() async throws {
        let repository = makeRepository(keys: [])
        stubAPIResponse(
            data: #"""
            {
              "orderId":"synthetic-order-id",
              "amount":50,
              "status":"UNKNOWN",
              "message":"充值状态暂无法确认，请稍后查看订单状态，避免重复提交。",
              "createdAt":"2026-04-28T10:00:00+08:00",
              "updatedAt":"2026-04-28T10:01:00+08:00",
              "retryAfter":60,
              "idempotencyKeyHash":"must-not-be-modeled",
              "payloadFingerprint":"must-not-be-modeled",
              "deviceIdHash":"must-not-be-modeled",
              "paymentUrlHash":"must-not-be-modeled",
              "manualReviewNote":"must-not-be-modeled"
            }
            """#
        )

        let order = try await repository.fetchChargeOrder(orderId: "synthetic-order-id")

        let request = try XCTUnwrap(ChargeRepositoryURLProtocol.requests.first)
        XCTAssertEqual(request.url?.path, "/api/card/charge/orders/synthetic-order-id")
        XCTAssertEqual(order.orderId, "synthetic-order-id")
        XCTAssertEqual(order.amount, 50)
        XCTAssertEqual(order.normalizedStatus, "UNKNOWN")

        let exposedFields = Set(Mirror(reflecting: order).children.compactMap(\.label))
        XCTAssertFalse(exposedFields.contains("idempotencyKeyHash"))
        XCTAssertFalse(exposedFields.contains("payloadFingerprint"))
        XCTAssertFalse(exposedFields.contains("deviceIdHash"))
        XCTAssertFalse(exposedFields.contains("paymentUrlHash"))
        XCTAssertFalse(exposedFields.contains("manualReviewNote"))
    }

    func testFetchRecentChargeOrdersUsesPagingAndStatusQuery() async throws {
        let repository = makeRepository(keys: [])
        stubAPIResponse(
            data: #"""
            [
              {"orderId":"synthetic-order-unknown","amount":50,"status":"UNKNOWN","retryAfter":60},
              {"orderId":"synthetic-order-processing","amount":20,"status":"PROCESSING","retryAfter":60}
            ]
            """#
        )

        let orders = try await repository.fetchRecentChargeOrders(page: 0, size: 5, status: "UNKNOWN")

        let request = try XCTUnwrap(ChargeRepositoryURLProtocol.requests.first)
        let components = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
        let queryItems = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
        XCTAssertEqual(request.url?.path, "/api/card/charge/orders")
        XCTAssertEqual(queryItems["page"], "0")
        XCTAssertEqual(queryItems["size"], "5")
        XCTAssertEqual(queryItems["status"], "UNKNOWN")
        XCTAssertEqual(orders.first?.orderId, "synthetic-order-unknown")
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
                makeKey: { generatedKeys.isEmpty ? "synthetic-charge-key" : generatedKeys.removeFirst() }
            )
        )
    }

    private func stubSuccessfulChargeResponse() {
        stubAPIResponse(
            data: #"""
            {
              "alipayURL":"https://pay.example.test/charge",
              "cookieList":[],
              "orderId":"synthetic-order-id",
              "status":"PAYMENT_SESSION_CREATED",
              "message":"支付请求已生成，请完成支付并刷新余额。该状态不代表最终到账。",
              "retryAfter":60
            }
            """#
        )
    }

    private func stubAPIResponse(data: String) {
        let responseBody = Data(
            """
            {"code":200,"success":true,"message":"","data":\(data)}
            """.utf8
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

@MainActor
final class ChargeViewModelTests: XCTestCase {
    func testSubmitChargeStoresReturnedOrderStatus() async throws {
        let repository = FakeChargeRepository()
        repository.submittedPayment = ChargePayment(
            alipayURL: "https://pay.example.test/charge",
            cookies: [],
            order: ChargeOrder(
                orderId: "synthetic-order-id",
                amount: 50,
                status: "PAYMENT_SESSION_CREATED",
                message: nil,
                createdAt: nil,
                updatedAt: nil,
                submittedAt: nil,
                completedAt: nil,
                retryAfter: nil
            )
        )
        let viewModel = ChargeViewModel(repository: repository)
        viewModel.amount = "50"
        viewModel.password = "synthetic-charge-password"

        await viewModel.submitChargeRequest()

        XCTAssertEqual(viewModel.latestOrder?.orderId, "synthetic-order-id")
        XCTAssertEqual(viewModel.latestOrder?.normalizedStatus, "PAYMENT_SESSION_CREATED")
        XCTAssertEqual(viewModel.recentOrders.first?.orderId, "synthetic-order-id")
    }

    func testRecentChargeOrderFailureShowsSafeError() async throws {
        let repository = FakeChargeRepository()
        repository.recentOrdersError = NetworkError.server(
            code: 500,
            message: "raw backend error idempotencyKeyHash paymentUrlHash"
        )
        let viewModel = ChargeViewModel(repository: repository)

        await viewModel.refreshContent()

        XCTAssertEqual(viewModel.orderErrorMessage, localizedString("charge.order.loadFailed"))
        XCTAssertFalse(viewModel.orderErrorMessage?.contains("idempotencyKeyHash") ?? true)
        XCTAssertFalse(viewModel.orderErrorMessage?.contains("paymentUrlHash") ?? true)
    }

    func testSubmitChargeFailureShowsSafeError() async throws {
        let repository = FakeChargeRepository()
        repository.submitError = NetworkError.server(
            code: 500,
            message: "raw backend error paymentUrlHash cookie"
        )
        let viewModel = ChargeViewModel(repository: repository)
        viewModel.amount = "50"
        viewModel.password = "synthetic-charge-password"

        await viewModel.submitChargeRequest()

        XCTAssertEqual(viewModel.errorMessage, localizedString("charge.submitFailed"))
        XCTAssertFalse(viewModel.errorMessage?.contains("paymentUrlHash") ?? true)
        XCTAssertFalse(viewModel.errorMessage?.contains("cookie") ?? true)
    }
}

@MainActor
private final class FakeChargeRepository: ChargeRepository {
    var submittedPayment = ChargePayment(alipayURL: "https://pay.example.test/charge", cookies: [])
    var submitError: Error?
    var recentOrders: [ChargeOrder] = []
    var recentOrdersError: Error?

    func fetchCardInfo() async throws -> CampusCardDashboard {
        CampusCardDashboard(
            info: CampusCardInfo(
                cardNumber: "6212261234567890",
                ownerName: "Synthetic User",
                balance: 52.50,
                status: .normal,
                lastUpdated: "just now"
            ),
            transactions: []
        )
    }

    func submitCharge(amount: Int, password: String) async throws -> ChargePayment {
        if let submitError {
            throw submitError
        }
        submittedPayment
    }

    func fetchChargeOrder(orderId: String) async throws -> ChargeOrder {
        ChargeOrder(
            orderId: orderId,
            amount: 50,
            status: "UNKNOWN",
            message: nil,
            createdAt: nil,
            updatedAt: nil,
            submittedAt: nil,
            completedAt: nil,
            retryAfter: nil
        )
    }

    func fetchRecentChargeOrders(page: Int, size: Int, status: String?) async throws -> [ChargeOrder] {
        if let recentOrdersError {
            throw recentOrdersError
        }
        return recentOrders
    }
}
