import Foundation

extension MockSeedData {
    static var marketplaceItems: [MarketplaceItem] {
        [
            MarketplaceItem(
                id: "market_001",
                title: mockLocalizedText(simplifiedChinese: "九成新 iPad 第九代", traditionalChinese: "九成新 iPad 第九代", english: "iPad 9th Gen in great condition", japanese: "美品 iPad 第9世代", korean: "상태 좋은 iPad 9세대"),
                price: 1780,
                summary: mockLocalizedText(simplifiedChinese: "平时记笔记用，带原装充电器和保护壳。", traditionalChinese: "平時記筆記用，帶原裝充電器和保護殼。", english: "Used mainly for note-taking, comes with the original charger and case.", japanese: "普段はノート用に使っていて、純正充電器とケース付きです。", korean: "평소 필기용으로 사용했고 정품 충전기와 케이스도 함께 드려요."),
                sellerName: MockSeedData.demoProfile.nickname,
                sellerAvatarURL: MockSeedData.demoProfile.avatarURL,
                postedAt: mockLocalizedText(simplifiedChinese: "12分钟前", traditionalChinese: "12分鐘前", english: "12 min ago", japanese: "12分前", korean: "12분 전"),
                location: mockLocalizedText(simplifiedChinese: "海珠校区宿舍区", traditionalChinese: "海珠校區宿舍區", english: "Haizhu campus dorm area", japanese: "海珠キャンパス寮エリア", korean: "하이주 캠퍼스 기숙사 구역"),
                state: .selling,
                tags: [
                    mockLocalizedText(simplifiedChinese: "数码", traditionalChinese: "數碼", english: "Digital", japanese: "デジタル", korean: "디지털"),
                    mockLocalizedText(simplifiedChinese: "平板", traditionalChinese: "平板", english: "Tablet", japanese: "タブレット", korean: "태블릿")
                ],
                previewImageURL: "https://example.com/market/ipad-preview.png"
            ),
            MarketplaceItem(
                id: "market_002",
                title: mockLocalizedText(simplifiedChinese: "数据库系统概论教材", traditionalChinese: "資料庫系統概論教材", english: "Database Systems textbook", japanese: "データベースシステム概論の教科書", korean: "데이터베이스 시스템 교재"),
                price: 28,
                summary: mockLocalizedText(simplifiedChinese: "有少量笔记，不影响使用，适合下学期上课前收一本。", traditionalChinese: "有少量筆記，不影響使用，適合下學期上課前收一本。", english: "Has a few notes inside but still in good usable condition. Good to pick up before next semester starts.", japanese: "少し書き込みがありますが使用には問題ありません。来学期の授業前にちょうどいいです。", korean: "필기가 조금 있지만 사용하는 데 문제 없고, 다음 학기 수업 전에 구해두기 좋아요."),
                sellerName: mockLocalizedText(simplifiedChinese: "周同学", traditionalChinese: "周同學", english: "Zhou", japanese: "周さん", korean: "저우"),
                sellerAvatarURL: "https://example.com/avatar/market-zhou.png",
                postedAt: mockLocalizedText(simplifiedChinese: "34分钟前", traditionalChinese: "34分鐘前", english: "34 min ago", japanese: "34分前", korean: "34분 전"),
                location: mockLocalizedText(simplifiedChinese: "教学楼 A 栋", traditionalChinese: "教學樓 A 棟", english: "Teaching Building A", japanese: "講義棟A", korean: "강의동 A"),
                state: .selling,
                tags: [
                    mockLocalizedText(simplifiedChinese: "教材", traditionalChinese: "教材", english: "Textbook", japanese: "教材", korean: "교재"),
                    mockLocalizedText(simplifiedChinese: "课程书", traditionalChinese: "課程書", english: "Course book", japanese: "授業本", korean: "수업 교재")
                ],
                previewImageURL: "https://example.com/market/book-preview.png"
            ),
            MarketplaceItem(
                id: "market_003",
                title: mockLocalizedText(simplifiedChinese: "宿舍落地风扇", traditionalChinese: "宿舍落地風扇", english: "Dorm standing fan", japanese: "寮用スタンド扇風機", korean: "기숙사용 스탠드 선풍기"),
                price: 65,
                summary: mockLocalizedText(simplifiedChinese: "毕业前出掉，风力正常，自提优先。", traditionalChinese: "畢業前出掉，風力正常，自提優先。", english: "Selling before graduation. Works well, pickup preferred.", japanese: "卒業前に手放します。風量は問題なく、直接受け渡し優先です。", korean: "졸업 전에 정리합니다. 작동은 정상이고 직거래 우선이에요."),
                sellerName: mockLocalizedText(simplifiedChinese: "陈学姐", traditionalChinese: "陳學姐", english: "Senior Chen", japanese: "陳先輩", korean: "선배 천"),
                sellerAvatarURL: "https://example.com/avatar/market-chen.png",
                postedAt: mockLocalizedText(simplifiedChinese: "1小时前", traditionalChinese: "1小時前", english: "1 hr ago", japanese: "1時間前", korean: "1시간 전"),
                location: mockLocalizedText(simplifiedChinese: "北苑 7 栋", traditionalChinese: "北苑 7 棟", english: "North Court Bldg 7", japanese: "北苑7棟", korean: "북원 7동"),
                state: .selling,
                tags: [
                    mockLocalizedText(simplifiedChinese: "宿舍", traditionalChinese: "宿舍", english: "Dorm", japanese: "寮", korean: "기숙사"),
                    mockLocalizedText(simplifiedChinese: "家电", traditionalChinese: "家電", english: "Appliance", japanese: "家電", korean: "가전")
                ],
                previewImageURL: "https://example.com/market/fan-preview.png"
            )
        ]
    }

    static var marketplaceDetailsByID: [String: MarketplaceDetail] {
        [
            "market_001": MarketplaceDetail(
                item: marketplaceItems[0],
                condition: mockLocalizedText(simplifiedChinese: "九成新", traditionalChinese: "九成新", english: "Like new", japanese: "美品", korean: "거의 새것"),
                description: mockLocalizedText(simplifiedChinese: "2024 年购入，电池健康良好，主要用于上课记笔记和刷题。支持现场验机。", traditionalChinese: "2024 年購入，電池健康良好，主要用於上課記筆記和刷題。支持現場驗機。", english: "Bought in 2024. Battery health is still great and it was mainly used for note-taking and practice. You can inspect it in person.", japanese: "2024年購入。バッテリー状態は良好で、主に授業のノート取りや演習に使っていました。現地で動作確認できます。", korean: "2024년에 구매했고 배터리 상태가 좋습니다. 주로 필기와 문제풀이용으로 썼고 현장 확인 가능합니다."),
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
                condition: mockLocalizedText(simplifiedChinese: "八五成新", traditionalChinese: "八五成新", english: "85% new", japanese: "8.5割ほど新品", korean: "85% 상태"),
                description: mockLocalizedText(simplifiedChinese: "封面边角有轻微折痕，正文完整。适合复习使用，价格可小刀。", traditionalChinese: "封面邊角有輕微折痕，正文完整。適合複習使用，價格可小刀。", english: "Slight creases on the cover corners, but the inside is intact. Good for review and the price is negotiable.", japanese: "表紙の角に少し折れがありますが、中身はきれいです。復習用に向いていて、価格は少し相談できます。", korean: "표지 모서리에 약간의 접힘은 있지만 본문은 멀쩡합니다. 복습용으로 좋고 가격도 조금 조정할 수 있어요."),
                contactHint: "\(localizedString("marketplace.contactQQPrefix"))87234561",
                sellerUsername: "zhou.market",
                sellerNickname: mockLocalizedText(simplifiedChinese: "周同学", traditionalChinese: "周同學", english: "Zhou", japanese: "周さん", korean: "저우"),
                sellerCollege: mockLocalizedText(simplifiedChinese: "计算机科学系", traditionalChinese: "計算機科學系", english: "Computer Science", japanese: "計算機科学", korean: "컴퓨터과학"),
                sellerMajor: mockLocalizedText(simplifiedChinese: "计算机科学与技术", traditionalChinese: "計算機科學與技術", english: "Computer Science and Technology", japanese: "計算機科学と技術", korean: "컴퓨터과학기술"),
                sellerGrade: mockLocalizedText(simplifiedChinese: "2022级", traditionalChinese: "2022級", english: "Class of 2022", japanese: "2022年入学", korean: "2022학번"),
                imageURLs: ["https://example.com/market/book-1.png"]
            ),
            "market_003": MarketplaceDetail(
                item: marketplaceItems[2],
                condition: mockLocalizedText(simplifiedChinese: "八成新", traditionalChinese: "八成新", english: "Good condition", japanese: "良好", korean: "양호"),
                description: mockLocalizedText(simplifiedChinese: "运行稳定，无明显异响，宿舍搬离前优先处理。", traditionalChinese: "運行穩定，無明顯異響，宿舍搬離前優先處理。", english: "Runs steadily with no obvious noise. Prefer to sell it before moving out of the dorm.", japanese: "動作は安定していて異音もありません。寮を出る前に優先して手放したいです。", korean: "작동은 안정적이고 이상 소음도 없습니다. 기숙사 퇴실 전에 우선 정리하려고 합니다."),
                contactHint: "\(localizedString("marketplace.contactQQPrefix"))92457731",
                sellerUsername: "chen.market",
                sellerNickname: mockLocalizedText(simplifiedChinese: "陈学姐", traditionalChinese: "陳學姐", english: "Senior Chen", japanese: "陳先輩", korean: "선배 천"),
                sellerCollege: mockLocalizedText(simplifiedChinese: "外语系", traditionalChinese: "外語系", english: "Foreign Languages", japanese: "外国語学科", korean: "외국어학과"),
                sellerMajor: mockLocalizedText(simplifiedChinese: "商务英语", traditionalChinese: "商務英語", english: "Business English", japanese: "ビジネス英語", korean: "비즈니스 영어"),
                sellerGrade: mockLocalizedText(simplifiedChinese: "2021级", traditionalChinese: "2021級", english: "Class of 2021", japanese: "2021年入学", korean: "2021학번"),
                imageURLs: ["https://example.com/market/fan-1.png"]
            )
        ]
    }
}
