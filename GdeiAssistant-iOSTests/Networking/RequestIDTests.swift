import XCTest
@testable import GdeiAssistant_iOS

final class RequestIDTests: XCTestCase {
    func testGenerateReturnsNonEmptyString() {
        XCTAssertFalse(RequestID.generate().isEmpty)
    }

    func testGenerateReturnsUniqueIDs() {
        let id1 = RequestID.generate()
        let id2 = RequestID.generate()
        XCTAssertNotEqual(id1, id2)
    }

    func testGenerateReturnsLowercaseUUIDFormat() {
        let id = RequestID.generate()
        XCTAssertEqual(id, id.lowercased(), "Expected lowercase ID")
        XCTAssertNotNil(UUID(uuidString: id), "Expected valid UUID structure")
    }
}
