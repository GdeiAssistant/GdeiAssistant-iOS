import Foundation

extension MockSeedData {
    static let marketplaceItems: [MarketplaceItem] = [
        MarketplaceItem(
            id: "market_001",
            title: "九成新 iPad 第九代",
            price: 1780,
            summary: "平时记笔记用，带原装充电器和保护壳。",
            sellerName: MockSeedData.demoProfile.nickname,
            sellerAvatarURL: MockSeedData.demoProfile.avatarURL,
            postedAt: "12分钟前",
            location: "海珠校区宿舍区",
            state: .selling,
            tags: ["数码", "平板"],
            previewImageURL: "https://example.com/market/ipad-preview.png"
        ),
        MarketplaceItem(
            id: "market_002",
            title: "数据库系统概论教材",
            price: 28,
            summary: "有少量笔记，不影响使用，适合下学期上课前收一本。",
            sellerName: "周同学",
            sellerAvatarURL: "https://example.com/avatar/market-zhou.png",
            postedAt: "34分钟前",
            location: "教学楼 A 栋",
            state: .selling,
            tags: ["教材", "课程书"],
            previewImageURL: "https://example.com/market/book-preview.png"
        ),
        MarketplaceItem(
            id: "market_003",
            title: "宿舍落地风扇",
            price: 65,
            summary: "毕业前出掉，风力正常，自提优先。",
            sellerName: "陈学姐",
            sellerAvatarURL: "https://example.com/avatar/market-chen.png",
            postedAt: "1小时前",
            location: "北苑 7 栋",
            state: .selling,
            tags: ["宿舍", "家电"],
            previewImageURL: "https://example.com/market/fan-preview.png"
        )
    ]

    static let marketplaceDetailsByID: [String: MarketplaceDetail] = [
        "market_001": MarketplaceDetail(
            item: marketplaceItems[0],
            condition: "九成新",
            description: "2024 年购入，电池健康良好，主要用于上课记笔记和刷题。支持现场验机。",
            contactHint: "\(localizedString("marketplace.contactQQPrefix"))231245678 / \(localizedString("marketplace.contactPhonePrefix"))13812345678",
            sellerUsername: MockSeedData.demoProfile.username,
            sellerNickname: MockSeedData.demoProfile.nickname,
            sellerCollege: MockSeedData.demoProfile.college,
            sellerMajor: MockSeedData.demoProfile.major,
            sellerGrade: MockSeedData.demoProfile.grade,
            imageURLs: [
                "https://example.com/market/ipad-1.png",
                "https://example.com/market/ipad-2.png"
            ]
        ),
        "market_002": MarketplaceDetail(
            item: marketplaceItems[1],
            condition: "八五成新",
            description: "封面边角有轻微折痕，正文完整。适合复习使用，价格可小刀。",
            contactHint: "\(localizedString("marketplace.contactQQPrefix"))87234561",
            sellerUsername: "zhou.market",
            sellerNickname: "周同学",
            sellerCollege: "计算机科学系",
            sellerMajor: "计算机科学与技术",
            sellerGrade: "2022级",
            imageURLs: ["https://example.com/market/book-1.png"]
        ),
        "market_003": MarketplaceDetail(
            item: marketplaceItems[2],
            condition: "八成新",
            description: "运行稳定，无明显异响，宿舍搬离前优先处理。",
            contactHint: "\(localizedString("marketplace.contactQQPrefix"))92457731",
            sellerUsername: "chen.market",
            sellerNickname: "陈学姐",
            sellerCollege: "外语系",
            sellerMajor: "商务英语",
            sellerGrade: "2021级",
            imageURLs: ["https://example.com/market/fan-1.png"]
        )
    ]
}
