import XCTest
@testable import GdeiAssistant_iOS

/// The optimistic like / comment / guess counters used to be rebuilt with six full
/// memberwise constructions. This test keeps the single `with(...)` helper honest:
/// a new stored field changes the Mirror labels and fails the first assertion.
final class ExpressPostCopyHelperTests: XCTestCase {

    private func labels(_ value: Any) -> [String] {
        Mirror(reflecting: value).children.compactMap { $0.label }
    }

    private func fields(_ value: Any) -> [String: String] {
        Dictionary(uniqueKeysWithValues: Mirror(reflecting: value).children.compactMap { child in
            child.label.map { ($0, String(describing: child.value)) }
        })
    }

    private func makePost() -> ExpressPost {
        ExpressPost(
            id: "express_test_001",
            nickname: "小明",
            targetName: "小红",
            contentPreview: "内容预览",
            publishTime: "昨天 20:00",
            likeCount: 5,
            commentCount: 2,
            guessCount: 3,
            correctGuessCount: 1,
            isLiked: false,
            canGuess: true,
            selfGender: .male,
            targetGender: .female
        )
    }

    func testHelperNamesEveryStoredField() {
        XCTAssertEqual(labels(makePost()), [
            "id", "nickname", "targetName", "contentPreview", "publishTime",
            "likeCount", "commentCount", "guessCount", "correctGuessCount",
            "isLiked", "canGuess", "selfGender", "targetGender"
        ], "A new stored field must also be added to ExpressPost.with(...)")
    }

    func testCopyKeepsEveryFieldItDoesNotChange() {
        let original = makePost()
        let copy = original.with(likeCount: 6, isLiked: true)
        let before = fields(original)
        let after = fields(copy)
        let changed: Set<String> = ["likeCount", "isLiked"]

        for (label, value) in before where !changed.contains(label) {
            XCTAssertEqual(after[label], value, "\(label) was dropped by with(...)")
        }
        XCTAssertEqual(copy.likeCount, 6)
        XCTAssertTrue(copy.isLiked)
        XCTAssertEqual(original.likeCount, 5, "with(...) must not mutate the original")
        XCTAssertFalse(original.isLiked)
    }

    func testCounterUpdatesComposeWithoutLosingOtherCounters() {
        let original = makePost()
        let commented = original.with(commentCount: original.commentCount + 1)
        let liked = commented.with(likeCount: commented.likeCount + 1, isLiked: true)
        let guessed = liked.with(
            guessCount: liked.guessCount + 1,
            correctGuessCount: liked.correctGuessCount + 1
        )

        XCTAssertEqual(guessed.commentCount, 3)
        XCTAssertEqual(guessed.likeCount, 6)
        XCTAssertEqual(guessed.guessCount, 4)
        XCTAssertEqual(guessed.correctGuessCount, 2)
        XCTAssertTrue(guessed.isLiked)
        XCTAssertTrue(guessed.canGuess)
        XCTAssertEqual(guessed.selfGender, .male)
        XCTAssertEqual(guessed.targetGender, .female)
        XCTAssertEqual(guessed.id, original.id)
    }
}
