import Foundation

@MainActor
final class MockDatingRepository: DatingRepository {
    private var profiles: [DatingProfile] = [
        DatingProfile(
            id: "dating_001",
            nickname: "晚风",
            headline: "想找一起夜跑和自习的搭子",
            college: "软件工程",
            major: "软件工程",
            grade: "大二",
            tags: [DatingTag(id: "area_0", title: "小姐姐")],
            bio: "希望你愿意一起跑步、看展，也能在考试周一起安静自习。",
            imageURL: nil,
            hometown: "广州",
            qq: nil,
            wechat: nil,
            isContactVisible: false,
            area: .girl
        ),
        DatingProfile(
            id: "dating_002",
            nickname: "阿辰",
            headline: "周末篮球和食堂探店都可以约",
            college: "电子信息",
            major: "电子信息",
            grade: "大三",
            tags: [DatingTag(id: "area_1", title: "小哥哥")],
            bio: "喜欢运动，也喜欢在校园里到处找新开的窗口。",
            imageURL: nil,
            hometown: "佛山",
            qq: nil,
            wechat: nil,
            isContactVisible: false,
            area: .boy
        )
    ]

    private var received: [DatingReceivedPick] = [
        DatingReceivedPick(id: "pick_001", senderName: "晴天", content: "看你也喜欢夜跑，想认识一下。", time: "10分钟前", status: .pending, avatarURL: nil)
    ]
    private var sent: [DatingSentPick] = [
        DatingSentPick(id: "pick_002", targetName: "晚风", content: "周末一起去图书馆吗？", status: .accepted, targetQq: "12345678", targetWechat: "wanfeng_run", targetAvatarURL: nil)
    ]
    private var myPosts: [DatingMyPost] = [
        DatingMyPost(id: "dating_900", name: "我自己", imageURL: nil, publishTime: "昨天", grade: "大三", faculty: "计算机科学", hometown: "广州", area: .boy, state: 1)
    ]

    func fetchProfiles(filter: DatingFilter) async throws -> [DatingProfile] {
        profiles.filter { $0.area == filter.area }
    }

    func fetchProfile(profileID: String) async throws -> DatingProfile {
        try await fetchProfileDetail(profileID: profileID).profile
    }

    func fetchProfileDetail(profileID: String) async throws -> DatingProfileDetail {
        guard let profile = profiles.first(where: { $0.id == profileID }) else {
            throw NetworkError.server(code: 404, message: "资料不存在")
        }
        return DatingProfileDetail(profile: profile, isPickNotAvailable: false)
    }

    func fetchReceivedPicks(start: Int) async throws -> [DatingReceivedPick] {
        Array(received.dropFirst(start).prefix(20))
    }

    func fetchSentPicks() async throws -> [DatingSentPick] {
        sent
    }

    func fetchMyPosts() async throws -> [DatingMyPost] {
        myPosts
    }

    func publish(draft: DatingPublishDraft) async throws {
        let profile = DatingProfile(
            id: "dating_mock_\(UUID().uuidString)",
            nickname: draft.nickname,
            headline: RemoteMapperSupport.truncated(draft.content, limit: 28),
            college: draft.faculty,
            major: draft.faculty,
            grade: gradeText(draft.grade),
            tags: [DatingTag(id: "area_\(draft.area.rawValue)", title: draft.area.title)],
            bio: draft.content,
            imageURL: draft.image == nil ? nil : "mock://dating/image",
            hometown: draft.hometown,
            qq: nil,
            wechat: nil,
            isContactVisible: false,
            area: draft.area
        )
        profiles.insert(profile, at: 0)
        myPosts.insert(
            DatingMyPost(
                id: profile.id,
                name: profile.nickname,
                imageURL: profile.imageURL,
                publishTime: "刚刚",
                grade: profile.grade,
                faculty: profile.college,
                hometown: profile.hometown,
                area: profile.area,
                state: 1
            ),
            at: 0
        )
    }

    func sendPick(profileID: String, content: String) async throws {
        guard let target = profiles.first(where: { $0.id == profileID }) else {
            throw NetworkError.server(code: 404, message: "资料不存在")
        }
        sent.insert(
            DatingSentPick(id: "pick_sent_\(UUID().uuidString)", targetName: target.nickname, content: content, status: .pending, targetQq: nil, targetWechat: nil, targetAvatarURL: target.imageURL),
            at: 0
        )
    }

    func updatePickState(pickID: String, state: DatingPickStatus) async throws {
        if let index = received.firstIndex(where: { $0.id == pickID }) {
            let item = received[index]
            received[index] = DatingReceivedPick(id: item.id, senderName: item.senderName, content: item.content, time: item.time, status: state, avatarURL: item.avatarURL)
        }
    }

    func hideProfile(profileID: String) async throws {
        myPosts.removeAll { $0.id == profileID }
    }

    private func gradeText(_ value: Int) -> String {
        switch value {
        case 1: return "大一"
        case 2: return "大二"
        case 3: return "大三"
        case 4: return "大四"
        default: return "未知年级"
        }
    }
}
