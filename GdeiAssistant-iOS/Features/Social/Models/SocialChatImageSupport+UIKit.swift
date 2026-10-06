import Foundation
import UIKit

extension SocialChatImageSupport {
    /// Convert picker content to a bounded JPEG, removing source metadata.
    nonisolated static func jpegData(from image: UIImage, maxBytes: Int = maxBytes) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let ratio = min(min(1, 4096 / max(size.width, size.height)),
                        sqrt(16_000_000 / (size.width * size.height)))
        let outputSize = CGSize(width: max(1, floor(size.width * ratio)),
                                height: max(1, floor(size.height * ratio)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(
            size: outputSize,
            format: format
        )
        let normalized = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))
            image.draw(in: CGRect(origin: .zero, size: outputSize))
        }
        var quality: CGFloat = 0.92
        while quality >= 0.35 {
            if let data = normalized.jpegData(compressionQuality: quality),
               data.count <= maxBytes, !data.isEmpty { return data }
            quality -= 0.08
        }
        return nil
    }

    nonisolated static func jpegUploadAsset(from image: UIImage, fileName: String) -> UploadImageAsset? {
        guard let data = jpegData(from: image) else { return nil }
        return UploadImageAsset(fileName: fileName, mimeType: "image/jpeg", data: data)
    }

    nonisolated static func jpegUploadAsset(data: Data, fileName: String) -> UploadImageAsset? {
        guard !data.isEmpty, data.count <= maxBytes, data.starts(with: [0xff, 0xd8, 0xff]),
              UIImage(data: data) != nil else { return nil }
        return UploadImageAsset(fileName: fileName, mimeType: "image/jpeg", data: data)
    }
}
