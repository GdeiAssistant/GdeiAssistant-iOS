import XCTest
@testable import GdeiAssistant_iOS

final class LibraryRemoteMapperTests: XCTestCase {
    func testMapBorrowRecordsRequiresSnAndCodeForRenewableState() {
        let renewable = BorrowBookDTO(
            id: "book-1",
            sn: "sn-1",
            code: "code-1",
            name: "计算机网络",
            author: "谢希仁",
            borrowDate: RemoteFlexibleString("2026-03-01"),
            returnDate: RemoteFlexibleString("2026-03-28"),
            renewTime: 1
        )
        let nonRenewable = BorrowBookDTO(
            id: "book-2",
            sn: "sn-2",
            code: nil,
            name: "操作系统",
            author: "汤小丹",
            borrowDate: RemoteFlexibleString("2026-03-02"),
            returnDate: RemoteFlexibleString("2026-03-29"),
            renewTime: 0
        )

        let records = LibraryRemoteMapper.mapBorrowRecords([renewable, nonRenewable])

        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records[0].renewable)
        XCTAssertEqual(records[0].status, "已续借1次")
        XCTAssertFalse(records[1].renewable)
        XCTAssertEqual(records[1].status, "待归还")
    }

    func testMapRenewRequestTrimsPasswordAndTokens() {
        let request = LibraryRenewRequest(
            sn: " sn-1 ",
            code: " code-1 ",
            password: " library-pass "
        )

        let dto = LibraryRemoteMapper.mapRenewRequest(request)

        XCTAssertEqual(dto.sn, "sn-1")
        XCTAssertEqual(dto.code, "code-1")
        XCTAssertEqual(dto.password, "library-pass")
    }
}
