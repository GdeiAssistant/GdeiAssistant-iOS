import XCTest
@testable import GdeiAssistant_iOS

private struct FlexibleStringBox: Decodable {
    let value: RemoteFlexibleString
}

private struct FlexibleDoubleBox: Decodable {
    let value: RemoteFlexibleDouble
}

final class RemoteMapperSupportTests: XCTestCase {
    func testRemoteFlexibleStringDecodesPrimitivePayloads() throws {
        let decoder = JSONDecoder()

        XCTAssertEqual(
            try decoder.decode(FlexibleStringBox.self, from: Data(#"{"value":"42"}"#.utf8)).value.rawValue,
            "42"
        )
        XCTAssertEqual(
            try decoder.decode(FlexibleStringBox.self, from: Data(#"{"value":42}"#.utf8)).value.rawValue,
            "42"
        )
        XCTAssertEqual(
            try decoder.decode(FlexibleStringBox.self, from: Data(#"{"value":42.5}"#.utf8)).value.rawValue,
            "42.5"
        )
        XCTAssertEqual(
            try decoder.decode(FlexibleStringBox.self, from: Data(#"{"value":true}"#.utf8)).value.rawValue,
            "true"
        )
        XCTAssertEqual(
            try decoder.decode(FlexibleStringBox.self, from: Data(#"{"value":null}"#.utf8)).value.rawValue,
            ""
        )
    }

    func testRemoteFlexibleDoubleDecodesNumericAndStringPayloads() throws {
        let decoder = JSONDecoder()

        XCTAssertEqual(
            try XCTUnwrap(decoder.decode(FlexibleDoubleBox.self, from: Data(#"{"value":42.5}"#.utf8)).value.rawValue),
            42.5,
            accuracy: 0.001
        )
        XCTAssertEqual(
            try XCTUnwrap(decoder.decode(FlexibleDoubleBox.self, from: Data(#"{"value":18}"#.utf8)).value.rawValue),
            18,
            accuracy: 0.001
        )
        XCTAssertEqual(
            try XCTUnwrap(decoder.decode(FlexibleDoubleBox.self, from: Data(#"{"value":" 99.25 "}"#.utf8)).value.rawValue),
            99.25,
            accuracy: 0.001
        )
        XCTAssertEqual(
            try XCTUnwrap(decoder.decode(FlexibleDoubleBox.self, from: Data(#"{"value":"约 12.5 元"}"#.utf8)).value.rawValue),
            12.5,
            accuracy: 0.001
        )
        XCTAssertNil(
            try decoder.decode(FlexibleDoubleBox.self, from: Data(#"{"value":null}"#.utf8)).value.rawValue
        )
    }

    func testDateTextFormatsSecondsAndMillisecondsInShanghaiTime() {
        XCTAssertEqual(
            RemoteMapperSupport.dateText(RemoteFlexibleString("1704067200"), fallback: "刚刚"),
            "2024-01-01 08:00"
        )
        XCTAssertEqual(
            RemoteMapperSupport.dateText(RemoteFlexibleString("1704067200000"), fallback: "刚刚"),
            "2024-01-01 08:00"
        )
    }

    func testDoubleExtractsFirstNumberFromMixedText() {
        XCTAssertEqual(
            RemoteMapperSupport.double(RemoteFlexibleString("约 12.5 元"), fallback: 0),
            12.5,
            accuracy: 0.001
        )
    }

    func testFirstNonEmptyAndTruncatedTrimWhitespace() {
        XCTAssertEqual(RemoteMapperSupport.firstNonEmpty(nil, " ", "  topic  "), "topic")
        XCTAssertEqual(RemoteMapperSupport.truncated("  abcdef  ", limit: 4), "abcd...")
    }
}
