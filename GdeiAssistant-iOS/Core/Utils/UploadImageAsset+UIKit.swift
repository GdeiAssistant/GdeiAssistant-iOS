import Foundation
import UIKit

extension UploadImageAsset {
    /// Decodes raw picker bytes, strips EXIF/source metadata by re-rendering,
    /// and compresses to a bounded JPEG upload asset using the shared chat image pipeline.
    nonisolated static func compressedJPEG(
        from rawData: Data,
        fileNamePrefix: String,
        maxBytes: Int = SocialChatImageSupport.maxBytes
    ) -> UploadImageAsset? {
        guard !rawData.isEmpty, let image = UIImage(data: rawData) else { return nil }
        guard let jpegData = SocialChatImageSupport.jpegData(from: image, maxBytes: maxBytes) else {
            return nil
        }
        return UploadImageAsset(
            fileName: "\(fileNamePrefix)-\(UUID().uuidString).jpg",
            mimeType: "image/jpeg",
            data: jpegData
        )
    }
}
