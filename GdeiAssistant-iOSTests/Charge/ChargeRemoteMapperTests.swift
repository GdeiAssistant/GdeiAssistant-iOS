import XCTest
@testable import GdeiAssistant_iOS

final class ChargeRemoteMapperTests: XCTestCase {
    func testChargeFormFieldsDoNotIncludeLegacyHmacFields() {
        let fields = ChargeRemoteMapper.chargeFormFields(
            amount: 50,
            password: "synthetic-charge-password"
        )
        let fieldNames = Set(fields.map(\.name))
        let valuesByName = Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0.value) })

        XCTAssertEqual(fieldNames, ["amount", "password"])
        XCTAssertEqual(valuesByName["amount"], "50")
        XCTAssertEqual(valuesByName["password"], "synthetic-charge-password")
        XCTAssertFalse(fieldNames.contains("hmac"))
        XCTAssertFalse(fieldNames.contains("timestamp"))
    }
}
