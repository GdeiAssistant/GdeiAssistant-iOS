import Foundation

extension MockFactory {
    static func makeSecretPosts() -> [SecretPost] {
        MockSeedData.secretPosts
    }

    static func makeSecretDetailsByID() -> [String: SecretPostDetail] {
        MockSeedData.secretDetailsByID
    }
}
