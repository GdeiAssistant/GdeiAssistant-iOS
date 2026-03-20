import XCTest
@testable import GdeiAssistant_iOS

final class MultipartFormDataBuilderTests: XCTestCase {
    func testFormURLEncoderEscapesReservedCharacters() {
        let payload = FormURLEncoder.encode(fields: [
            FormFieldValue(name: "keyword", value: "hello world"),
            FormFieldValue(name: "content", value: "a+b&=中文")
        ])

        XCTAssertEqual(
            String(decoding: payload, as: UTF8.self),
            "keyword=hello+world&content=a%2Bb%26%3D%E4%B8%AD%E6%96%87"
        )
    }

    func testMultipartBuilderIncludesFieldsFilesAndClosingBoundary() {
        let payload = MultipartFormDataBuilder.build(
            fields: [FormFieldValue(name: "title", value: "cover")],
            files: [
                MultipartFormFile(
                    name: "image",
                    fileName: "cover.jpg",
                    mimeType: "image/jpeg",
                    data: Data("abc123".utf8)
                )
            ]
        )
        let boundary = payload.contentType.replacingOccurrences(of: "multipart/form-data; boundary=", with: "")
        let body = String(decoding: payload.body, as: UTF8.self)

        XCTAssertTrue(body.contains("--\(boundary)\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\ncover\r\n"))
        XCTAssertTrue(body.contains("Content-Disposition: form-data; name=\"image\"; filename=\"cover.jpg\"\r\n"))
        XCTAssertTrue(body.contains("Content-Type: image/jpeg\r\n\r\nabc123\r\n"))
        XCTAssertTrue(body.hasSuffix("--\(boundary)--\r\n"))
    }
}
