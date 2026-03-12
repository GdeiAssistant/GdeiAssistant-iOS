import Foundation

@MainActor
final class MockDatingRepository: DatingRepository {
    private var received: [DatingReceivedPick] = [
        DatingReceivedPick(id: "pick_001", senderName: "晴天", content: "看你也喜欢夜跑，想认识一下。", time: "10分钟前", status: .pending, avatarURL: nil)
    ]
    private var sent: [DatingSentPick] = [
        DatingSentPick(id: "pick_002", targetName: "晚风", content: "周末一起去图书馆吗？", status: .accepted, targetQq: "12345678", targetWechat: "wanfeng_run", targetAvatarURL: nil)
    ]
    private var myPosts: [DatingMyPost] = [
        DatingMyPost(id: "dating_900", name: "我自己", imageURL: nil, publishTime: "昨天", grade: "大三", faculty: "计算机科学", hometown: "广州", area: .boy, state: 1)
    ]

    func fetchReceivedPicks() async throws -> [DatingReceivedPick] {
        received
    }

    func fetchSentPicks() async throws -> [DatingSentPick] {
        sent
    }

    func fetchMyPosts() async throws -> [DatingMyPost] {
        myPosts
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
}
