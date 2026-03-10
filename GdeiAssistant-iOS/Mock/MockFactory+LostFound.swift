import Foundation

extension MockFactory {
    static func makeLostFoundItems() -> [LostFoundItem] {
        MockSeedData.lostFoundItems
    }

    static func makeLostFoundDetailsByID() -> [String: LostFoundDetail] {
        MockSeedData.lostFoundDetailsByID
    }
}
