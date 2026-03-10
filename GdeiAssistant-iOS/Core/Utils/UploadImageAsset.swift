import Foundation

struct UploadImageAsset: Identifiable, Hashable, Codable {
    let id: UUID
    let fileName: String
    let mimeType: String
    let data: Data

    init(
        id: UUID = UUID(),
        fileName: String,
        mimeType: String,
        data: Data
    ) {
        self.id = id
        self.fileName = fileName
        self.mimeType = mimeType
        self.data = data
    }

    var fileSizeText: String {
        ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }

    var multipartFile: MultipartFormFile {
        MultipartFormFile(
            name: "",
            fileName: fileName,
            mimeType: mimeType,
            data: data
        )
    }
}
