import XCTest
@testable import GdeiAssistant_iOS

@MainActor
final class MockDataConsistencyTests: XCTestCase {

    // MARK: - Marketplace

    func testMarketplaceItemsHaveAllRequiredFields() async throws {
        let repository = MockMarketplaceRepository()
        let items = try await repository.fetchItems(typeID: nil)

        XCTAssertFalse(items.isEmpty)

        for item in items {
            XCTAssertFalse(item.id.isEmpty, "id must not be empty")
            XCTAssertFalse(item.title.isEmpty, "title must not be empty: \(item.id)")
            XCTAssertGreaterThanOrEqual(item.price, 0, "price must be non-negative: \(item.id)")
            XCTAssertFalse(item.sellerName.isEmpty, "sellerName must not be empty: \(item.id)")
            XCTAssertFalse(item.postedAt.isEmpty, "postedAt must not be empty: \(item.id)")
            XCTAssertFalse(item.location.isEmpty, "location must not be empty: \(item.id)")
        }
    }

    // MARK: - Express

    func testExpressPostsHaveAllRequiredFields() async throws {
        let repository = MockExpressRepository()
        let posts = try await repository.fetchPosts(start: 0, size: 20)

        XCTAssertFalse(posts.isEmpty)

        for post in posts {
            XCTAssertFalse(post.id.isEmpty, "id must not be empty")
            XCTAssertFalse(post.nickname.isEmpty, "nickname must not be empty: \(post.id)")
            XCTAssertFalse(post.targetName.isEmpty, "targetName must not be empty: \(post.id)")
            XCTAssertFalse(post.contentPreview.isEmpty, "contentPreview must not be empty: \(post.id)")
            XCTAssertFalse(post.publishTime.isEmpty, "publishTime must not be empty: \(post.id)")
            XCTAssertGreaterThanOrEqual(post.likeCount, 0, "likeCount must be non-negative: \(post.id)")
            XCTAssertGreaterThanOrEqual(post.commentCount, 0, "commentCount must be non-negative: \(post.id)")
        }
    }

    // MARK: - News

    func testNewsItemsHaveAllRequiredFields() async throws {
        let repository = MockNewsRepository()
        let items = try await repository.fetchNews(start: 0, size: 20)

        XCTAssertFalse(items.isEmpty)

        for item in items {
            XCTAssertFalse(item.id.isEmpty, "id must not be empty")
            XCTAssertFalse(item.title.isEmpty, "title must not be empty: \(item.id)")
            XCTAssertGreaterThan(item.type, 0, "type must be positive: \(item.id)")
            XCTAssertFalse(item.publishDate.isEmpty, "publishDate must not be empty: \(item.id)")
            XCTAssertFalse(item.content.isEmpty, "content must not be empty: \(item.id)")
            XCTAssertNotNil(item.sourceURL, "sourceURL must not be nil: \(item.id)")
            XCTAssertFalse(item.sourceURL?.isEmpty ?? true, "sourceURL must not be empty: \(item.id)")
        }
    }

    // MARK: - Marketplace seed data

    func testMarketplaceSeedItemsHaveConsistentState() {
        let items = MockSeedData.marketplaceItems

        XCTAssertFalse(items.isEmpty)

        for item in items {
            XCTAssertFalse(item.id.isEmpty, "id must not be empty")
            XCTAssertFalse(item.title.isEmpty, "title must not be empty: \(item.id)")
            XCTAssertFalse(item.tags.isEmpty, "tags must not be empty: \(item.id)")
        }
    }

    // MARK: - Announcements

    func testAnnouncementItemsHaveAllRequiredFields() {
        let items = MockSeedData.announcementDetailsByID

        XCTAssertFalse(items.isEmpty)

        for (key, item) in items {
            XCTAssertFalse(item.id.isEmpty, "id must not be empty: key=\(key)")
            XCTAssertFalse(item.title.isEmpty, "title must not be empty: \(item.id)")
            XCTAssertFalse(item.content.isEmpty, "content must not be empty: \(item.id)")
            XCTAssertFalse(item.createdAt.isEmpty, "createdAt must not be empty: \(item.id)")
        }
    }
}
