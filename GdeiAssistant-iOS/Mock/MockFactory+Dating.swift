import Foundation

extension MockFactory {
    static func makeDatingTags() -> [DatingTag] {
        MockSeedData.datingTags
    }

    static func makeDatingProfiles() -> [DatingProfile] {
        MockSeedData.datingProfiles
    }
}
