import XCTest
@testable import GdeiAssistant_iOS

/// These tests pin the hidden link between a model's stored fields and its copy helper.
/// Adding a stored field changes the Mirror labels, so the label test fails until
/// `with(...)` is extended to carry the new field across.
final class MarketplaceCopyHelperTests: XCTestCase {

    private func labels(_ value: Any) -> [String] {
        Mirror(reflecting: value).children.compactMap { $0.label }
    }

    private func fields(_ value: Any) -> [String: String] {
        Dictionary(uniqueKeysWithValues: Mirror(reflecting: value).children.compactMap { child in
            child.label.map { ($0, String(describing: child.value)) }
        })
    }

    private func makeItem(typeID: Int? = 4) -> MarketplaceItem {
        MarketplaceItem(
            id: "market_test_001",
            title: "二手车",
            price: 42.5,
            summary: "九成新",
            sellerName: "小明",
            sellerAvatarURL: "https://example.com/avatar.png",
            authorId: "user-demo-0001",
            postedAt: "昨天",
            location: "海珠校区",
            state: .selling,
            tags: ["交通工具"],
            previewImageURL: "https://example.com/preview.png",
            typeID: typeID
        )
    }

    private func makeDetail() -> MarketplaceDetail {
        MarketplaceDetail(
            item: makeItem(),
            condition: "交通工具",
            description: "描述",
            contactHint: "QQ 123456",
            sellerUsername: "demo",
            sellerNickname: "小明",
            sellerCollege: "学院",
            sellerMajor: "专业",
            sellerGrade: "2023",
            imageURLs: ["https://example.com/1.png"],
            ownedByCurrentUser: true
        )
    }

    func testItemHelperNamesEveryStoredField() {
        XCTAssertEqual(labels(makeItem()), [
            "id", "title", "price", "summary", "sellerName", "sellerAvatarURL",
            "authorId", "postedAt", "location", "state", "tags", "previewImageURL", "typeID"
        ], "A new stored field must also be added to MarketplaceItem.with(...)")
    }

    func testItemCopyKeepsEveryFieldItDoesNotChange() {
        let original = makeItem()
        let copy = original.with(state: .sold)
        let before = fields(original)
        let after = fields(copy)

        for (label, value) in before where label != "state" {
            XCTAssertEqual(after[label], value, "\(label) was dropped by with(...)")
        }
        XCTAssertEqual(copy.state, .sold)
        XCTAssertEqual(original.state, .selling, "with(...) must not mutate the original")
    }

    func testItemCopyCanChangeTheCategory() {
        let item = makeItem(typeID: 4)

        XCTAssertEqual(item.with(typeID: 9).typeID, 9)
        XCTAssertEqual(item.typeID, 4)
    }

    func testDetailHelperNamesEveryStoredField() {
        XCTAssertEqual(labels(makeDetail()), [
            "item", "condition", "description", "contactHint", "sellerUsername",
            "sellerNickname", "sellerCollege", "sellerMajor", "sellerGrade",
            "imageURLs", "ownedByCurrentUser"
        ], "A new stored field must also be added to MarketplaceDetail.with(...)")
    }

    func testDetailCopyKeepsOwnershipAndSellerFields() {
        let detail = makeDetail()
        let copy = detail.with(
            item: detail.item.with(state: .sold),
            condition: "已售出",
            imageURLs: []
        )

        XCTAssertTrue(copy.ownedByCurrentUser)
        XCTAssertEqual(copy.sellerUsername, "demo")
        XCTAssertEqual(copy.sellerGrade, "2023")
        XCTAssertEqual(copy.description, detail.description)
        XCTAssertEqual(copy.contactHint, detail.contactHint)
        XCTAssertEqual(copy.item.typeID, 4)
        XCTAssertEqual(copy.item.state, .sold)
        XCTAssertEqual(copy.condition, "已售出")
        XCTAssertEqual(copy.imageURLs, [])
        XCTAssertTrue(detail.ownedByCurrentUser, "with(...) must not mutate the original")
    }
}

@MainActor
final class MarketplaceCopyIntegrationTests: XCTestCase {

    private func editDraft(typeID: Int) -> MarketplaceUpdateDraft {
        MarketplaceUpdateDraft(
            title: "改过的标题",
            price: 99,
            description: "改过的描述",
            location: "新地点",
            typeID: typeID,
            qq: "123456",
            phone: nil
        )
    }

    func testEditingAnItemAppliesTheNewCategory() async throws {
        let repository = MockMarketplaceRepository()
        let items = try await repository.fetchItems(typeID: nil)
        guard let target = items.first(where: { $0.state == .selling }) else {
            XCTFail("Expected a selling seed item")
            return
        }

        try await repository.updateItem(itemID: target.id, draft: editDraft(typeID: 3))

        let updated = try await repository.fetchItems(typeID: nil).first { $0.id == target.id }
        XCTAssertEqual(updated?.typeID, 3, "Editing must not silently drop the item category")
        XCTAssertEqual(updated?.title, "改过的标题")
        XCTAssertEqual(updated?.previewImageURL, target.previewImageURL)
    }

    func testChangingStateKeepsTheEditedCategory() async throws {
        let repository = MockMarketplaceRepository()
        let items = try await repository.fetchItems(typeID: nil)
        guard let target = items.first(where: { $0.state == .selling }) else {
            XCTFail("Expected a selling seed item")
            return
        }

        try await repository.updateItem(itemID: target.id, draft: editDraft(typeID: 5))
        try await repository.updateItemState(itemID: target.id, state: .sold)

        let detail = try await repository.fetchItemDetail(itemID: target.id)
        XCTAssertEqual(detail.item.typeID, 5)
        XCTAssertEqual(detail.item.state, .sold)
        XCTAssertEqual(detail.item.previewImageURL, target.previewImageURL)
    }
}
