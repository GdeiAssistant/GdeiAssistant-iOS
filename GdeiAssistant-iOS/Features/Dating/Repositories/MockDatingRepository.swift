import Foundation

@MainActor
final class MockDatingRepository: DatingRepository {
    private var hallProfiles: [DatingProfile] = [
        DatingProfile(
            id: "dating_001",
            nickname: "晴天",
            headline: "大二 · 英语教育",
            college: "英语教育",
            major: "佛山",
            grade: "大二",
            tags: [DatingTag(id: "area", title: DatingArea.girl.title), DatingTag(id: "hometown", title: "佛山")],
            bio: "喜欢夜跑和音乐节，也愿意认真聊天。",
            imageURL: nil,
            hometown: "佛山",
            qq: "55667788",
            wechat: "sunny-run",
            isContactVisible: false,
            area: .girl
        ),
        DatingProfile(
            id: "dating_002",
            nickname: "晚风",
            headline: "大四 · 汉语言文学",
            college: "汉语言文学",
            major: "深圳",
            grade: "大四",
            tags: [DatingTag(id: "area", title: DatingArea.girl.title), DatingTag(id: "hometown", title: "深圳")],
            bio: "周末常去图书馆和咖啡馆，希望认识节奏相近的人。",
            imageURL: nil,
            hometown: "深圳",
            qq: "88990011",
            wechat: "wanfeng_reading",
            isContactVisible: false,
            area: .girl
        )
    ]

    private var received: [DatingReceivedPick] = [
        DatingReceivedPick(id: "pick_001", senderName: "晴天", content: "看你也喜欢夜跑，想认识一下。", time: "10分钟前", status: .pending, avatarURL: nil)
    ]
    private var sent: [DatingSentPick] = [
        DatingSentPick(id: "pick_002", targetName: "晚风", content: "周末一起去图书馆吗？", status: .accepted, targetQq: "12345678", targetWechat: "wanfeng_run", targetAvatarURL: nil)
    ]
    private var myProfiles: [DatingProfile] = [
        DatingProfile(
            id: "dating_900",
            nickname: "我自己",
            headline: "大三 · 计算机科学系",
            college: "计算机科学系",
            major: "广州",
            grade: "大三",
            tags: [DatingTag(id: "area", title: DatingArea.boy.title), DatingTag(id: "hometown", title: "广州")],
            bio: "能聊天、会运动、作息稳定。",
            imageURL: nil,
            hometown: "广州",
            qq: "214365870",
            wechat: "mock_wechat",
            isContactVisible: false,
            area: .boy
        )
    ]

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

        throw NSError(domain: "MockDatingRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到卖室友资料"])
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
                publishTime: "已发布",
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
            return "大一"
        case 2:
            return "大二"
        case 3:
            return "大三"
        default:
            return "大四"
        }
    }
}
