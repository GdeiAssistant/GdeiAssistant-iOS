import Foundation

struct FormFieldValue: Hashable {
    let name: String
    let value: String
}

struct MultipartFormFile: Hashable {
    let name: String
    let fileName: String
    let mimeType: String
    let data: Data
}

struct MultipartFormDataPayload {
    let body: Data
    let contentType: String
}

enum FormURLEncoder {
    nonisolated static func encode(fields: [FormFieldValue]) -> Data {
        let encoded = fields
            .map { field in
                "\(escape(field.name))=\(escape(field.value))"
            }
            .joined(separator: "&")

        return Data(encoded.utf8)
    }

    nonisolated private static func escape(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._* "))
        let escaped = text
            .addingPercentEncoding(withAllowedCharacters: allowed) ?? text
        return escaped.replacingOccurrences(of: " ", with: "+")
    }
}

enum MultipartFormDataBuilder {
    nonisolated static func build(
        fields: [FormFieldValue],
        files: [MultipartFormFile]
    ) -> MultipartFormDataPayload {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        fields.forEach { field in
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(field.name)\"\r\n\r\n".utf8))
            body.append(Data("\(field.value)\r\n".utf8))
        }

        files.forEach { file in
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data(
                "Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.fileName)\"\r\n".utf8
            ))
            body.append(Data("Content-Type: \(file.mimeType)\r\n\r\n".utf8))
            body.append(file.data)
            body.append(Data("\r\n".utf8))
        }

        body.append(Data("--\(boundary)--\r\n".utf8))

        return MultipartFormDataPayload(
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }
}
