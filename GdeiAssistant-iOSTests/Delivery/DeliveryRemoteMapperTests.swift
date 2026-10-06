import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class DeliveryRemoteMapperTests: XCTestCase {
    func testMissingOrInvalidIdentifiersAreRejected() throws {
        for json in ["{}", #"{"orderId":0}"#, #"{"orderId":"invalid"}"#] {
            let dto = try JSONDecoder().decode(DeliveryOrderRemoteDTO.self, from: Data(json.utf8))
            XCTAssertThrowsError(try DeliveryRemoteMapper.mapOrder(dto))
        }
        let trade = try JSONDecoder().decode(DeliveryTradeRemoteDTO.self, from: Data(#"{"tradeId":1}"#.utf8))
        XCTAssertThrowsError(try DeliveryRemoteMapper.mapTrade(trade))
    }

    func testMissingStateAndRoleNeverInventPermissions() throws {
        let dto = try JSONDecoder().decode(DeliveryDetailRemoteDTO.self, from: Data(#"{"order":{"orderId":1}}"#.utf8))
        let detail = try DeliveryRemoteMapper.mapDetail(dto)
        XCTAssertEqual(detail.order.state, .unknown)
        XCTAssertFalse(detail.canViewSensitiveInfo)
    }
    func testMarketplaceDoesNotInventIdentifiersOrSellingState() throws {
        let invalid = try JSONDecoder().decode(MarketplaceItemDTO.self, from: Data(#"{"name":"Missing ID","state":1}"#.utf8))
        XCTAssertTrue(MarketplaceRemoteMapper.mapItems([invalid]).isEmpty)
        XCTAssertEqual(MarketplaceRemoteMapper.mapState(nil), .unknown)
        XCTAssertEqual(LostFoundRemoteMapper.mapState(nil), .unknown)
        let detail = try JSONDecoder().decode(MarketplaceDetailDTO.self, from: Data(#"{"item":{"id":1}}"#.utf8))
        XCTAssertThrowsError(try MarketplaceRemoteMapper.mapDetail(detail))
    }

}
