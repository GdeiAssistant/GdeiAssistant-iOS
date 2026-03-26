import Foundation

extension MockSeedData {
    static let secretVoiceURL = "https://file-examples.com/storage/fe1e9b0a2a2cd0dfd0c5b5f/2017/11/file_example_MP3_700KB.mp3"

    static var secretPosts: [SecretPost] {
        [
            SecretPost(
                id: "secret_001",
                username: "gdeiassistant",
                themeID: 4,
                title: mockLocalizedText(simplifiedChinese: "小组作业节奏完全对不上", traditionalChinese: "小組作業節奏完全對不上", english: "Our group project is completely out of sync", japanese: "グループ課題のペースが全然合わない", korean: "조별 과제 호흡이 완전히 안 맞아요"),
                summary: mockLocalizedText(simplifiedChinese: "本来想好好推进项目，结果队友这周都在赶别的课，自己一个人顶着有点累。", traditionalChinese: "本來想好好推進項目，結果隊友這週都在趕別的課，自己一個人頂著有點累。", english: "I wanted to push the project forward, but my teammates were busy with other classes this week, so handling it alone has been exhausting.", japanese: "ちゃんと進めたかったのに、今週はチームのみんなが別の授業で手一杯で、一人で抱えるのが少ししんどい。", korean: "프로젝트를 잘 진행하고 싶었는데 팀원들이 이번 주엔 다른 수업 때문에 바빠서 혼자 버티기가 조금 힘들어요."),
                createdAt: mockLocalizedText(simplifiedChinese: "9分钟前", traditionalChinese: "9分鐘前", english: "9 min ago", japanese: "9分前", korean: "9분 전"),
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
                title: mockLocalizedText(simplifiedChinese: "语音树洞", traditionalChinese: "語音樹洞", english: "Voice secret", japanese: "音声ツリーホール", korean: "음성 트리홀"),
                summary: mockLocalizedText(simplifiedChinese: "点击进入详情播放语音内容", traditionalChinese: "點擊進入詳情播放語音內容", english: "Open details to play the voice post", japanese: "詳細を開いて音声を再生", korean: "상세 화면에서 음성 재생"),
                createdAt: mockLocalizedText(simplifiedChinese: "27分钟前", traditionalChinese: "27分鐘前", english: "27 min ago", japanese: "27分前", korean: "27분 전"),
                likeCount: 18,
                commentCount: 1,
                isLiked: true,
                type: 1,
                timer: 0,
                state: 0,
                voiceURL: secretVoiceURL
            )
        ]
    }

    static var secretDetailsByID: [String: SecretPostDetail] {
        [
            "secret_001": SecretPostDetail(
                post: secretPosts[0],
                content: mockLocalizedText(simplifiedChinese: "这门课的项目其实挺有意思，但时间卡得太紧了。白天要上课，晚上还要准备另一门实验，现在脑子里全是 deadline。只是想找个地方说出来，缓一口气。", traditionalChinese: "這門課的項目其實挺有意思，但時間卡得太緊了。白天要上課，晚上還要準備另一門實驗，現在腦子裡全是 deadline。只是想找個地方說出來，緩一口氣。", english: "This course project is actually interesting, but the schedule is way too tight. I have classes during the day and another lab to prepare for at night, so my head is full of deadlines. Just wanted a place to say it out loud and breathe.", japanese: "この授業のプロジェクト自体は面白いけれど、スケジュールが本当にきつい。昼は授業、夜は別の実験の準備で、頭の中は締め切りだらけ。少し吐き出して息を整えたかっただけ。", korean: "이 과목 프로젝트 자체는 꽤 흥미로운데 일정이 너무 빡빡해요. 낮엔 수업, 밤엔 다른 실험 준비까지 해야 해서 머릿속이 마감으로 가득해요. 그냥 어디엔가 털어놓고 한숨 돌리고 싶었어요."),
                comments: [
                    SecretComment(id: "secret_comment_001", authorName: mockLocalizedText(simplifiedChinese: "匿名同学", traditionalChinese: "匿名同學", english: "Anonymous student", japanese: "匿名の学生", korean: "익명 학생"), content: mockLocalizedText(simplifiedChinese: "先把最急的一项做完，其他事情一件件来。", traditionalChinese: "先把最急的一項做完，其他事情一件件來。", english: "Finish the most urgent task first, then handle the rest one by one.", japanese: "いちばん急ぎのものから片付けて、あとは一つずつ進めよう。", korean: "가장 급한 일부터 끝내고, 나머지는 하나씩 해봐요."), createdAt: mockLocalizedText(simplifiedChinese: "5分钟前", traditionalChinese: "5分鐘前", english: "5 min ago", japanese: "5分前", korean: "5분 전"), avatarTheme: 1),
                    SecretComment(id: "secret_comment_002", authorName: mockLocalizedText(simplifiedChinese: "夜读人", traditionalChinese: "夜讀人", english: "Night reader", japanese: "夜ふかし読書家", korean: "밤 독서러"), content: mockLocalizedText(simplifiedChinese: "你已经很努力了，今晚先早点休息。", traditionalChinese: "你已經很努力了，今晚先早點休息。", english: "You are already doing a lot. Try to rest a bit earlier tonight.", japanese: "もう十分頑張ってるよ。今夜は少し早めに休もう。", korean: "이미 충분히 열심히 하고 있어요. 오늘 밤은 조금 일찍 쉬어요."), createdAt: mockLocalizedText(simplifiedChinese: "3分钟前", traditionalChinese: "3分鐘前", english: "3 min ago", japanese: "3分前", korean: "3분 전"), avatarTheme: 2)
                ]
            ),
            "secret_002": SecretPostDetail(
                post: secretPosts[1],
                content: mockLocalizedText(simplifiedChinese: "这是一条语音树洞，点击播放按钮可试听录音内容。", traditionalChinese: "這是一條語音樹洞，點擊播放按鈕可試聽錄音內容。", english: "This is a voice secret. Tap the play button to preview the recording.", japanese: "これは音声ツリーホールです。再生ボタンを押すと録音を試聴できます。", korean: "이건 음성 트리홀이에요. 재생 버튼을 누르면 녹음을 들어볼 수 있어요."),
                comments: [
                    SecretComment(id: "secret_comment_003", authorName: mockLocalizedText(simplifiedChinese: "路过的同学", traditionalChinese: "路過的同學", english: "Passing student", japanese: "通りすがりの学生", korean: "지나가던 학생"), content: mockLocalizedText(simplifiedChinese: "稳住这个节奏，你会越来越顺。", traditionalChinese: "穩住這個節奏，你會越來越順。", english: "Keep this pace and things will feel smoother and smoother.", japanese: "このペースを保てば、きっとどんどん楽になるよ。", korean: "이 리듬만 유지하면 점점 더 괜찮아질 거예요."), createdAt: mockLocalizedText(simplifiedChinese: "12分钟前", traditionalChinese: "12分鐘前", english: "12 min ago", japanese: "12分前", korean: "12분 전"), avatarTheme: 3)
                ]
            )
        ]
    }
}
