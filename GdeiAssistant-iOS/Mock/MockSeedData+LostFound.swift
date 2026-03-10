import Foundation

extension MockSeedData {
    static let lostFoundItems: [LostFoundItem] = [
        LostFoundItem(
            id: "lf_001",
            title: "寻一把黑色折叠伞",
            type: .lost,
            itemTypeID: 5,
            summary: "昨晚在图书馆一楼自助借还机附近遗失。",
            location: "图书馆一楼",
            createdAt: "18分钟前",
            state: .active,
            previewImageURL: "https://example.com/lostfound/umbrella-preview.png"
        ),
        LostFoundItem(
            id: "lf_002",
            title: "拾到一卡通一张",
            type: .found,
            itemTypeID: 1,
            summary: "卡面姓名显示为李同学，已暂存到宿管阿姨处。",
            location: "北苑 3 栋门口",
            createdAt: "42分钟前",
            state: .active,
            previewImageURL: "https://example.com/lostfound/card-preview.png"
        ),
        LostFoundItem(
            id: "lf_003",
            title: "寻 AirPods 保护壳",
            type: .lost,
            itemTypeID: 10,
            summary: "透明壳，背面贴了蓝色笑脸贴纸。",
            location: "教学楼 C201",
            createdAt: "1小时前",
            state: .active,
            previewImageURL: "https://example.com/lostfound/airpods-preview.png"
        )
    ]

    static let lostFoundDetailsByID: [String: LostFoundDetail] = [
        "lf_001": LostFoundDetail(
            item: lostFoundItems[0],
            description: "雨伞手柄处有白色胶带，晚上闭馆前还在使用，怀疑离开时落在借还机座位旁。",
            contactHint: "QQ：231245678 / 微信：demo_umbrella",
            statusText: "寻主/寻物中",
            ownerUsername: MockSeedData.demoProfile.username,
            ownerNickname: MockSeedData.demoProfile.nickname,
            ownerAvatarURL: MockSeedData.demoProfile.avatarURL,
            imageURLs: ["https://example.com/lostfound/umbrella-1.png"]
        ),
        "lf_002": LostFoundDetail(
            item: lostFoundItems[1],
            description: "已将校园卡交给宿管阿姨保管，卡主可凭学生证领取。",
            contactHint: "QQ：83457892",
            statusText: "寻主/寻物中",
            ownerUsername: "li.picker",
            ownerNickname: "李同学",
            ownerAvatarURL: "https://example.com/avatar/lostfound-li.png",
            imageURLs: ["https://example.com/lostfound/card-1.png"]
        ),
        "lf_003": LostFoundDetail(
            item: lostFoundItems[2],
            description: "保护壳内侧写有 ZY 字样，如果捡到请留言。",
            contactHint: "微信：zy_airpods",
            statusText: "寻主/寻物中",
            ownerUsername: "zy.finder",
            ownerNickname: "ZY",
            ownerAvatarURL: "https://example.com/avatar/lostfound-zy.png",
            imageURLs: ["https://example.com/lostfound/airpods-1.png"]
        )
    ]
}
