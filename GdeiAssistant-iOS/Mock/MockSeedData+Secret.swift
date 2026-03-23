import Foundation

extension MockSeedData {
    static let secretVoiceURL = "https://file-examples.com/storage/fe1e9b0a2a2cd0dfd0c5b5f/2017/11/file_example_MP3_700KB.mp3"

    static let secretPosts: [SecretPost] = [
        SecretPost(
            id: "secret_001",
            username: "gdeiassistant",
            themeID: 4,
            title: "小组作业节奏完全对不上",
            summary: "本来想好好推进项目，结果队友这周都在赶别的课，自己一个人顶着有点累。",
            createdAt: "9分钟前",
            likeCount: 24,
            commentCount: 2,
            isLiked: false,
            type: 0,
            timer: 1,
            state: 0,
            voiceURL: nil
        ),
        SecretPost(
            id: "secret_002",
            username: "20230018",
            themeID: 9,
            title: "语音树洞",
            summary: "点击进入详情播放语音内容",
            createdAt: "27分钟前",
            likeCount: 18,
            commentCount: 1,
            isLiked: true,
            type: 1,
            timer: 0,
            state: 0,
            voiceURL: secretVoiceURL
        )
    ]

    static let secretDetailsByID: [String: SecretPostDetail] = [
        "secret_001": SecretPostDetail(
            post: secretPosts[0],
            content: "这门课的项目其实挺有意思，但时间卡得太紧了。白天要上课，晚上还要准备另一门实验，现在脑子里全是 deadline。只是想找个地方说出来，缓一口气。",
            comments: [
                SecretComment(id: "secret_comment_001", authorName: "匿名同学", content: "先把最急的一项做完，其他事情一件件来。", createdAt: "5分钟前", avatarTheme: 1),
                SecretComment(id: "secret_comment_002", authorName: "夜读人", content: "你已经很努力了，今晚先早点休息。", createdAt: "3分钟前", avatarTheme: 2)
            ]
        ),
        "secret_002": SecretPostDetail(
            post: secretPosts[1],
            content: "这是一条语音树洞，点击播放按钮可试听录音内容。",
            comments: [
                SecretComment(id: "secret_comment_003", authorName: "路过的同学", content: "稳住这个节奏，你会越来越顺。", createdAt: "12分钟前", avatarTheme: 3)
            ]
        )
    ]
}
