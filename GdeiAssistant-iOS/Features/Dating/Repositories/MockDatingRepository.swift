import Foundation

@MainActor
final class MockDatingRepository: DatingRepository {
    private var hallProfiles: [DatingProfile]
    private var received: [DatingReceivedPick]
    private var sent: [DatingSentPick]
    private var myProfiles: [DatingProfile]

    init() {
        hallProfiles = Self.makeHallProfiles()
        received = Self.makeReceivedPicks()
        sent = Self.makeSentPicks()
        myProfiles = Self.makeMyProfiles()
    }

    func fetchProfiles(filter: DatingFilter) async throws -> [DatingProfile] {
        hallProfiles.filter { $0.area == filter.area }
    }

    func fetchProfileDetail(profileID: String) async throws -> DatingProfileDetail {
        if let profile = hallProfiles.first(where: { $0.id == profileID }) {
            let sentPick = sent.first(where: { $0.targetName == profile.nickname })
            return DatingProfileDetail(
                profile: DatingProfile(
                    id: profile.id,
                    nickname: profile.nickname,
                    headline: profile.headline,
                    college: profile.college,
                    major: profile.major,
                    grade: profile.grade,
                    tags: profile.tags,
                    bio: profile.bio,
                    imageURL: profile.imageURL,
                    hometown: profile.hometown,
                    qq: profile.qq,
                    wechat: profile.wechat,
                    isContactVisible: sentPick?.status == .accepted,
                    area: profile.area
                ),
                isPickNotAvailable: sentPick != nil
            )
        }

        throw NSError(
            domain: "MockDatingRepository",
            code: 404,
            userInfo: [
                NSLocalizedDescriptionKey: mockLocalizedText(
                    simplifiedChinese: "未找到卖室友资料",
                    traditionalChinese: "未找到賣室友資料",
                    english: "Dating profile not found",
                    japanese: "プロフィールが見つかりません",
                    korean: "프로필을 찾을 수 없습니다"
                )
            ]
        )
    }

    func publishProfile(draft: DatingPublishDraft) async throws {
        let profile = DatingProfile(
            id: "dating_\(Int.random(in: 901 ... 999))",
            nickname: draft.nickname,
            headline: "\(gradeText(draft.grade)) · \(draft.faculty)",
            college: draft.faculty,
            major: draft.hometown,
            grade: gradeText(draft.grade),
            tags: [DatingTag(id: "area", title: draft.area.title), DatingTag(id: "hometown", title: draft.hometown)],
            bio: draft.content,
            imageURL: nil,
            hometown: draft.hometown,
            qq: draft.qq,
            wechat: draft.wechat,
            isContactVisible: false,
            area: draft.area
        )
        myProfiles.insert(profile, at: 0)
    }

    func submitPick(profileID: String, content: String) async throws {
        guard let profile = hallProfiles.first(where: { $0.id == profileID }) else { return }
        sent.insert(
            DatingSentPick(
                id: "pick_\(Int.random(in: 100 ... 999))",
                targetName: profile.nickname,
                content: content,
                status: .pending,
                targetQq: nil,
                targetWechat: nil,
                targetAvatarURL: profile.imageURL
            ),
            at: 0
        )
    }

    func fetchReceivedPicks() async throws -> [DatingReceivedPick] {
        received
    }

    func fetchSentPicks() async throws -> [DatingSentPick] {
        sent
    }

    func fetchMyPosts() async throws -> [DatingMyPost] {
        myProfiles.map {
            DatingMyPost(
                id: $0.id,
                name: $0.nickname,
                imageURL: $0.imageURL,
                publishTime: mockLocalizedText(
                    simplifiedChinese: "已发布",
                    traditionalChinese: "已發佈",
                    english: "Published",
                    japanese: "公開済み",
                    korean: "게시됨"
                ),
                grade: $0.grade,
                faculty: $0.college,
                hometown: $0.hometown,
                area: $0.area,
                state: 1
            )
        }
    }

    func updatePickState(pickID: String, state: DatingPickStatus) async throws {
        if let index = received.firstIndex(where: { $0.id == pickID }) {
            let item = received[index]
            received[index] = DatingReceivedPick(id: item.id, senderName: item.senderName, content: item.content, time: item.time, status: state, avatarURL: item.avatarURL)
        }
    }

    func hideProfile(profileID: String) async throws {
        myProfiles.removeAll { $0.id == profileID }
    }

    private func gradeText(_ grade: Int) -> String {
        switch grade {
        case 1:
            return mockLocalizedText(simplifiedChinese: "大一", traditionalChinese: "大一", english: "Year 1", japanese: "1年生", korean: "1학년")
        case 2:
            return mockLocalizedText(simplifiedChinese: "大二", traditionalChinese: "大二", english: "Year 2", japanese: "2年生", korean: "2학년")
        case 3:
            return mockLocalizedText(simplifiedChinese: "大三", traditionalChinese: "大三", english: "Year 3", japanese: "3年生", korean: "3학년")
        default:
            return mockLocalizedText(simplifiedChinese: "大四", traditionalChinese: "大四", english: "Year 4", japanese: "4年生", korean: "4학년")
        }
    }

    private static func makeHallProfiles() -> [DatingProfile] {
        [
            DatingProfile(
                id: "dating_001",
                nickname: mockLocalizedText(simplifiedChinese: "晴天", traditionalChinese: "晴天", english: "Sunny", japanese: "晴れ", korean: "써니"),
                headline: mockLocalizedText(simplifiedChinese: "大二 · 英语教育", traditionalChinese: "大二 · 英語教育", english: "Year 2 · English Education", japanese: "2年生 ・ 英語教育", korean: "2학년 · 영어교육"),
                college: mockLocalizedText(simplifiedChinese: "英语教育", traditionalChinese: "英語教育", english: "English Education", japanese: "英語教育", korean: "영어교육"),
                major: mockLocalizedText(simplifiedChinese: "佛山", traditionalChinese: "佛山", english: "Foshan", japanese: "佛山", korean: "포산"),
                grade: mockLocalizedText(simplifiedChinese: "大二", traditionalChinese: "大二", english: "Year 2", japanese: "2年生", korean: "2학년"),
                tags: [DatingTag(id: "area", title: DatingArea.girl.title), DatingTag(id: "hometown", title: mockLocalizedText(simplifiedChinese: "佛山", traditionalChinese: "佛山", english: "Foshan", japanese: "佛山", korean: "포산"))],
                bio: mockLocalizedText(simplifiedChinese: "喜欢夜跑和音乐节，也愿意认真聊天。", traditionalChinese: "喜歡夜跑和音樂節，也願意認真聊天。", english: "Likes night runs and music festivals, and is happy to have sincere conversations.", japanese: "夜ランと音楽フェスが好きで、落ち着いて話すのも好きです。", korean: "야간 러닝과 음악 페스티벌을 좋아하고, 진지한 대화도 좋아해요."),
                imageURL: nil,
                hometown: mockLocalizedText(simplifiedChinese: "佛山", traditionalChinese: "佛山", english: "Foshan", japanese: "佛山", korean: "포산"),
                qq: "55667788",
                wechat: "sunny-run",
                isContactVisible: false,
                area: .girl
            ),
            DatingProfile(
                id: "dating_002",
                nickname: mockLocalizedText(simplifiedChinese: "晚风", traditionalChinese: "晚風", english: "Evening Breeze", japanese: "夕風", korean: "저녁바람"),
                headline: mockLocalizedText(simplifiedChinese: "大四 · 汉语言文学", traditionalChinese: "大四 · 漢語言文學", english: "Year 4 · Chinese Language and Literature", japanese: "4年生 ・ 中国語文学", korean: "4학년 · 중어중문학"),
                college: mockLocalizedText(simplifiedChinese: "汉语言文学", traditionalChinese: "漢語言文學", english: "Chinese Language and Literature", japanese: "中国語文学", korean: "중어중문학"),
                major: mockLocalizedText(simplifiedChinese: "深圳", traditionalChinese: "深圳", english: "Shenzhen", japanese: "深圳", korean: "선전"),
                grade: mockLocalizedText(simplifiedChinese: "大四", traditionalChinese: "大四", english: "Year 4", japanese: "4年生", korean: "4학년"),
                tags: [DatingTag(id: "area", title: DatingArea.girl.title), DatingTag(id: "hometown", title: mockLocalizedText(simplifiedChinese: "深圳", traditionalChinese: "深圳", english: "Shenzhen", japanese: "深圳", korean: "선전"))],
                bio: mockLocalizedText(simplifiedChinese: "周末常去图书馆和咖啡馆，希望认识节奏相近的人。", traditionalChinese: "週末常去圖書館和咖啡館，希望認識節奏相近的人。", english: "Often spends weekends in the library or a cafe and hopes to meet someone with a similar rhythm.", japanese: "週末は図書館やカフェで過ごすことが多く、似たペースの人と知り合えたらうれしいです。", korean: "주말엔 도서관이나 카페에 자주 가고, 비슷한 리듬의 사람을 만나고 싶어요."),
                imageURL: nil,
                hometown: mockLocalizedText(simplifiedChinese: "深圳", traditionalChinese: "深圳", english: "Shenzhen", japanese: "深圳", korean: "선전"),
                qq: "88990011",
                wechat: "wanfeng_reading",
                isContactVisible: false,
                area: .girl
            )
        ]
    }

    private static func makeReceivedPicks() -> [DatingReceivedPick] {
        [
            DatingReceivedPick(
                id: "pick_001",
                senderName: mockLocalizedText(simplifiedChinese: "晴天", traditionalChinese: "晴天", english: "Sunny", japanese: "晴れ", korean: "써니"),
                content: mockLocalizedText(simplifiedChinese: "看你也喜欢夜跑，想认识一下。", traditionalChinese: "看你也喜歡夜跑，想認識一下。", english: "I noticed you like night running too and wanted to get to know you.", japanese: "夜ランが好きそうだったので、少し話してみたいです。", korean: "야간 러닝을 좋아하는 것 같아서 한번 알아가고 싶었어요."),
                time: mockLocalizedText(simplifiedChinese: "10分钟前", traditionalChinese: "10分鐘前", english: "10 min ago", japanese: "10分前", korean: "10분 전"),
                status: .pending,
                avatarURL: nil
            )
        ]
    }

    private static func makeSentPicks() -> [DatingSentPick] {
        [
            DatingSentPick(
                id: "pick_002",
                targetName: mockLocalizedText(simplifiedChinese: "晚风", traditionalChinese: "晚風", english: "Evening Breeze", japanese: "夕風", korean: "저녁바람"),
                content: mockLocalizedText(simplifiedChinese: "周末一起去图书馆吗？", traditionalChinese: "週末一起去圖書館嗎？", english: "Want to go to the library together this weekend?", japanese: "週末、一緒に図書館へ行きませんか。", korean: "주말에 같이 도서관 갈래요?"),
                status: .accepted,
                targetQq: "12345678",
                targetWechat: "wanfeng_run",
                targetAvatarURL: nil
            )
        ]
    }

    private static func makeMyProfiles() -> [DatingProfile] {
        [
            DatingProfile(
                id: "dating_900",
                nickname: mockLocalizedText(simplifiedChinese: "我自己", traditionalChinese: "我自己", english: "Me", japanese: "自分", korean: "나"),
                headline: mockLocalizedText(simplifiedChinese: "大三 · 计算机科学系", traditionalChinese: "大三 · 計算機科學系", english: "Year 3 · Computer Science", japanese: "3年生 ・ 計算機科学", korean: "3학년 · 컴퓨터과학"),
                college: mockLocalizedText(simplifiedChinese: "计算机科学系", traditionalChinese: "計算機科學系", english: "Computer Science", japanese: "計算機科学", korean: "컴퓨터과학"),
                major: mockLocalizedText(simplifiedChinese: "广州", traditionalChinese: "廣州", english: "Guangzhou", japanese: "広州", korean: "광저우"),
                grade: mockLocalizedText(simplifiedChinese: "大三", traditionalChinese: "大三", english: "Year 3", japanese: "3年生", korean: "3학년"),
                tags: [DatingTag(id: "area", title: DatingArea.boy.title), DatingTag(id: "hometown", title: mockLocalizedText(simplifiedChinese: "广州", traditionalChinese: "廣州", english: "Guangzhou", japanese: "広州", korean: "광저우"))],
                bio: mockLocalizedText(simplifiedChinese: "能聊天、会运动、作息稳定。", traditionalChinese: "能聊天、會運動、作息穩定。", english: "Easy to talk to, likes sports, and keeps a steady routine.", japanese: "話しやすくて運動も好き、生活リズムは安定しています。", korean: "대화도 편하고 운동도 좋아하고, 생활 패턴도 안정적이에요."),
                imageURL: nil,
                hometown: mockLocalizedText(simplifiedChinese: "广州", traditionalChinese: "廣州", english: "Guangzhou", japanese: "広州", korean: "광저우"),
                qq: "214365870",
                wechat: "mock_wechat",
                isContactVisible: false,
                area: .boy
            )
        ]
    }
}
