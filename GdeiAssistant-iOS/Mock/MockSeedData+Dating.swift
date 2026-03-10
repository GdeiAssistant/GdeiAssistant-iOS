import Foundation

extension MockSeedData {
    static let datingTags: [DatingTag] = [
        DatingTag(id: "study", title: "学习搭子"),
        DatingTag(id: "fitness", title: "运动搭子"),
        DatingTag(id: "food", title: "饭搭子"),
        DatingTag(id: "concert", title: "演出搭子")
    ]

    static let datingProfiles: [DatingProfile] = [
        DatingProfile(
            id: "dating_001",
            nickname: "周也",
            headline: "想找自习和英语口语搭子",
            college: "外国语学院",
            major: "商务英语",
            grade: "2024级",
            tags: [datingTags[0]],
            bio: "晚上一般会在图书馆二楼自习，最近在准备六级和教师资格证，希望找一个能互相监督的人。"
        ),
        DatingProfile(
            id: "dating_002",
            nickname: "阿豪",
            headline: "晚饭后一起操场跑步",
            college: "体育学院",
            major: "社会体育指导",
            grade: "2023级",
            tags: [datingTags[1], datingTags[2]],
            bio: "一周至少跑四次，节奏不快，欢迎零基础一起坚持。跑完可以去北区食堂补碳。"
        ),
        DatingProfile(
            id: "dating_003",
            nickname: "Mia",
            headline: "想约音乐节和 livehouse 伙伴",
            college: "音乐学院",
            major: "音乐表演",
            grade: "2022级",
            tags: [datingTags[3], datingTags[2]],
            bio: "偏爱独立流行和现场演出，平时也会去学校音乐厅听演出，聊天轻松就行。"
        )
    ]
}
