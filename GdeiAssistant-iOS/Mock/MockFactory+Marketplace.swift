import Foundation

extension MockFactory {
    static func makeMarketplaceItems() -> [MarketplaceItem] {
        MockSeedData.marketplaceItems
    }

    static func makeMarketplaceDetailsByID() -> [String: MarketplaceDetail] {
        MockSeedData.marketplaceDetailsByID
    }
}
