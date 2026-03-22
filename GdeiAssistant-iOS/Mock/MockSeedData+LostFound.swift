import Foundation

extension MockSeedData {
    static var lostFoundItems: [LostFoundItem] {
        [
            LostFoundItem(
                id: "lf_001",
                title: localizedString("mock.lostFound.seed.item1.title"),
                type: .lost,
                itemTypeID: 5,
                summary: localizedString("mock.lostFound.seed.item1.summary"),
                location: localizedString("mock.lostFound.seed.item1.location"),
                createdAt: localizedString("mock.lostFound.seed.item1.createdAt"),
                state: .active,
                previewImageURL: "https://example.com/lostfound/umbrella-preview.png"
            ),
            LostFoundItem(
                id: "lf_002",
                title: localizedString("mock.lostFound.seed.item2.title"),
                type: .found,
                itemTypeID: 1,
                summary: localizedString("mock.lostFound.seed.item2.summary"),
                location: localizedString("mock.lostFound.seed.item2.location"),
                createdAt: localizedString("mock.lostFound.seed.item2.createdAt"),
                state: .active,
                previewImageURL: "https://example.com/lostfound/card-preview.png"
            ),
            LostFoundItem(
                id: "lf_003",
                title: localizedString("mock.lostFound.seed.item3.title"),
                type: .lost,
                itemTypeID: 10,
                summary: localizedString("mock.lostFound.seed.item3.summary"),
                location: localizedString("mock.lostFound.seed.item3.location"),
                createdAt: localizedString("mock.lostFound.seed.item3.createdAt"),
                state: .active,
                previewImageURL: "https://example.com/lostfound/airpods-preview.png"
            )
        ]
    }

    static var lostFoundDetailsByID: [String: LostFoundDetail] {
        [
            "lf_001": LostFoundDetail(
                item: lostFoundItems[0],
                description: localizedString("mock.lostFound.seed.detail1.description"),
                contactHint: localizedString("mock.lostFound.seed.detail1.contactHint"),
                statusText: localizedString("mock.lostFound.seed.statusText.active"),
                ownerUsername: MockSeedData.demoProfile.username,
                ownerNickname: MockSeedData.demoProfile.nickname,
                ownerAvatarURL: MockSeedData.demoProfile.avatarURL,
                imageURLs: ["https://example.com/lostfound/umbrella-1.png"]
            ),
            "lf_002": LostFoundDetail(
                item: lostFoundItems[1],
                description: localizedString("mock.lostFound.seed.detail2.description"),
                contactHint: localizedString("mock.lostFound.seed.detail2.contactHint"),
                statusText: localizedString("mock.lostFound.seed.statusText.active"),
                ownerUsername: "li.picker",
                ownerNickname: localizedString("mock.lostFound.seed.detail2.ownerNickname"),
                ownerAvatarURL: "https://example.com/avatar/lostfound-li.png",
                imageURLs: ["https://example.com/lostfound/card-1.png"]
            ),
            "lf_003": LostFoundDetail(
                item: lostFoundItems[2],
                description: localizedString("mock.lostFound.seed.detail3.description"),
                contactHint: localizedString("mock.lostFound.seed.detail3.contactHint"),
                statusText: localizedString("mock.lostFound.seed.statusText.active"),
                ownerUsername: "zy.finder",
                ownerNickname: "ZY",
                ownerAvatarURL: "https://example.com/avatar/lostfound-zy.png",
                imageURLs: ["https://example.com/lostfound/airpods-1.png"]
            )
        ]
    }
}
