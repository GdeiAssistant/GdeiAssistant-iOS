import XCTest
@testable import GdeiAssistant_iOS

/// A counting spy that wraps any SecretRepository and records the number of
/// underlying method calls, allowing tests to assert exact call counts.
@MainActor
final class CountingSecretRepositorySpy: SecretRepository {
    private let backing: any SecretRepository

    var fetchPostsCallCount = 0
    var fetchMyPostsCallCount = 0
    var fetchDetailCallCount = 0
    var publishCallCount = 0
    var submitCommentCallCount = 0
    var setLikeCallCount = 0

    init(backing: any SecretRepository) {
        self.backing = backing
    }

    func fetchPosts() async throws -> [SecretPost] {
        fetchPostsCallCount += 1
        return try await backing.fetchPosts()
    }

    func fetchMyPosts() async throws -> [SecretPost] {
        fetchMyPostsCallCount += 1
        return try await backing.fetchMyPosts()
    }

    func fetchDetail(postID: String) async throws -> SecretPostDetail {
        fetchDetailCallCount += 1
        return try await backing.fetchDetail(postID: postID)
    }

    func publish(draft: SecretDraft) async throws {
        publishCallCount += 1
        try await backing.publish(draft: draft)
    }

    func submitComment(postID: String, content: String) async throws {
        submitCommentCallCount += 1
        try await backing.submitComment(postID: postID, content: content)
    }

    func setLike(postID: String, liked: Bool) async throws {
        setLikeCallCount += 1
        try await backing.setLike(postID: postID, liked: liked)
    }
}

@MainActor
final class SecretDetailNoDuplicateFetchTests: XCTestCase {

    /// fetchDetail on SecretViewModel should call the repository exactly once
    /// (detail endpoint), not make redundant duplicate calls. The repository
    /// implementation bundles detail + comments into a single fetchDetail call,
    /// so the ViewModel must not issue a separate request.
    func testFetchDetailMakesExactlyOneRepositoryCall() async throws {
        let spy = CountingSecretRepositorySpy(backing: MockSecretRepository())
        let viewModel = SecretViewModel(repository: spy)

        // Load posts first so there is a known post ID to query
        await viewModel.loadIfNeeded()
        let posts = viewModel.posts
        XCTAssertFalse(posts.isEmpty, "Need at least one post to test detail fetch")

        let postID = posts[0].id
        spy.fetchDetailCallCount = 0 // reset after loadIfNeeded

        _ = try await viewModel.fetchDetail(postID: postID)

        XCTAssertEqual(
            spy.fetchDetailCallCount, 1,
            "fetchDetail should call repository.fetchDetail exactly once (not 2 or 3 times)"
        )
    }

    /// submitComment triggers a comment POST followed by a detail refresh.
    /// The total repository calls should be:
    ///   1 x submitComment + 1 x fetchDetail = 2 calls total (not 3).
    func testSubmitCommentMakesExactlyTwoRepositoryCalls_notThree() async throws {
        let spy = CountingSecretRepositorySpy(backing: MockSecretRepository())
        let viewModel = SecretViewModel(repository: spy)

        await viewModel.loadIfNeeded()
        let posts = viewModel.posts
        XCTAssertFalse(posts.isEmpty)

        let postID = posts[0].id

        // Reset counters after initial load
        spy.submitCommentCallCount = 0
        spy.fetchDetailCallCount = 0

        _ = try await viewModel.submitComment(postID: postID, content: "Test")

        let totalCalls = spy.submitCommentCallCount + spy.fetchDetailCallCount
        XCTAssertEqual(spy.submitCommentCallCount, 1, "should call submitComment once")
        XCTAssertEqual(spy.fetchDetailCallCount, 1, "should call fetchDetail once after comment")
        XCTAssertEqual(totalCalls, 2, "total repository calls should be 2 (submitComment + fetchDetail), not 3")
    }

    /// setLike triggers a like toggle followed by a detail refresh.
    /// The total repository calls should be:
    ///   1 x setLike + 1 x fetchDetail = 2 calls total (not 3).
    func testSetLikeMakesExactlyTwoRepositoryCalls_notThree() async throws {
        let spy = CountingSecretRepositorySpy(backing: MockSecretRepository())
        let viewModel = SecretViewModel(repository: spy)

        await viewModel.loadIfNeeded()
        let posts = viewModel.posts
        XCTAssertFalse(posts.isEmpty)

        let postID = posts[0].id

        spy.setLikeCallCount = 0
        spy.fetchDetailCallCount = 0

        _ = try await viewModel.setLike(postID: postID, liked: true)

        let totalCalls = spy.setLikeCallCount + spy.fetchDetailCallCount
        XCTAssertEqual(spy.setLikeCallCount, 1, "should call setLike once")
        XCTAssertEqual(spy.fetchDetailCallCount, 1, "should call fetchDetail once after like toggle")
        XCTAssertEqual(totalCalls, 2, "total repository calls should be 2 (setLike + fetchDetail), not 3")
    }
}
