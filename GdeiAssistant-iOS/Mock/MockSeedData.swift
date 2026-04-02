import Foundation

enum MockSeedData {
    static var demoProfile: UserProfile {
        let localeIdentifier = AppLanguage.currentIdentifier()
        let labels = LocalizedProfileCatalog.catalog(for: localeIdentifier).defaultOptions
        let computerFaculty = labels.faculties.first(where: { $0.code == 11 })
        let softwareEngineering = computerFaculty?.majors.first(where: { $0.code == "software_engineering" })
        let location = localizedMockLocation(localeIdentifier)
        let hometown = localizedMockHometown(localeIdentifier)

        return UserProfile(
            id: "u_gdeiassistant",
            username: "gdeiassistant",
            nickname: localizedMockProfileText(
                simplifiedChinese: "林知远",
                traditionalChinese: "林知遠",
                english: "Lin Zhiyuan",
                japanese: "リン・ジーユエン",
                korean: "린즈위안",
                localeIdentifier: localeIdentifier
            ),
            avatarURL: "https://example.com/avatar/student.png",
            college: computerFaculty?.label ?? "",
            collegeCode: 11,
            major: softwareEngineering?.label ?? "",
            majorCode: "software_engineering",
            grade: "2023",
            bio: localizedMockProfileText(
                simplifiedChinese: "喜欢做实用的小工具，也在准备 iOS 开发实习。",
                traditionalChinese: "喜歡做實用的小工具，也在準備 iOS 開發實習。",
                english: "Enjoys building practical tools and is preparing for an iOS development internship.",
                japanese: "実用的な小さなツールを作るのが好きで、iOS 開発インターンの準備もしています。",
                korean: "실용적인 작은 도구를 만드는 것을 좋아하고, iOS 개발 인턴도 준비하고 있습니다.",
                localeIdentifier: localeIdentifier
            ),
            birthday: "2004-09-16",
            location: location.displayName,
            locationSelection: location,
            hometown: hometown.displayName,
            hometownSelection: hometown,
            ipArea: localizedMockProfileText(
                simplifiedChinese: "广东",
                traditionalChinese: "廣東",
                english: "Guangdong",
                japanese: "広東",
                korean: "광둥",
                localeIdentifier: localeIdentifier
            )
        )
    }

    static var dashboard: HomeDashboard {
        let localeIdentifier = AppLanguage.currentIdentifier()

        return HomeDashboard(
            greeting: mockLocalizedText(
                simplifiedChinese: "早上好，林知远",
                traditionalChinese: "早上好，林知遠",
                english: "Good morning, Lin Zhiyuan",
                japanese: "おはよう、リン・ジーユエン",
                korean: "좋은 아침이에요, 린즈위안",
                localeIdentifier: localeIdentifier
            ),
            reminderText: mockLocalizedText(
                simplifiedChinese: "今天 14:00 在教学楼 A201 有《移动应用开发》实验课，记得提前 10 分钟到教室。",
                traditionalChinese: "今天 14:00 在教學樓 A201 有《移動應用開發》實驗課，記得提前 10 分鐘到教室。",
                english: "You have a Mobile App Development lab at 14:00 in Teaching Building A201 today. Remember to get there 10 minutes early.",
                japanese: "今日は 14:00 から A201 教室で「モバイルアプリ開発」の実験があります。10 分前には教室に着いておきましょう。",
                korean: "오늘 14:00에 A201 강의실에서 모바일 앱 개발 실습이 있어요. 10분 전에 도착하는 걸 잊지 마세요.",
                localeIdentifier: localeIdentifier
            ),
            quickActions: [
                HomeQuickAction(id: "schedule", title: mockLocalizedText(simplifiedChinese: "课表", traditionalChinese: "課表", english: "Schedule", japanese: "時間割", korean: "수업표", localeIdentifier: localeIdentifier), icon: "calendar"),
                HomeQuickAction(id: "score", title: mockLocalizedText(simplifiedChinese: "成绩", traditionalChinese: "成績", english: "Grades", japanese: "成績", korean: "성적", localeIdentifier: localeIdentifier), icon: "chart.bar"),
                HomeQuickAction(id: "campus_card", title: mockLocalizedText(simplifiedChinese: "校园卡", traditionalChinese: "校園卡", english: "Campus Card", japanese: "学生証", korean: "캠퍼스 카드", localeIdentifier: localeIdentifier), icon: "creditcard"),
                HomeQuickAction(id: "library", title: mockLocalizedText(simplifiedChinese: "图书馆", traditionalChinese: "圖書館", english: "Library", japanese: "図書館", korean: "도서관", localeIdentifier: localeIdentifier), icon: "books.vertical"),
                HomeQuickAction(id: "cet", title: mockLocalizedText(simplifiedChinese: "四六级", traditionalChinese: "四六級", english: "CET", japanese: "CET", korean: "CET", localeIdentifier: localeIdentifier), icon: "doc.text.magnifyingglass")
            ],
            recentItems: [
                mockLocalizedText(simplifiedChinese: "图书馆座位预约", traditionalChinese: "圖書館座位預約", english: "Library seat reservation", japanese: "図書館座席予約", korean: "도서관 좌석 예약", localeIdentifier: localeIdentifier),
                mockLocalizedText(simplifiedChinese: "教学楼空教室查询", traditionalChinese: "教學樓空教室查詢", english: "Empty classroom lookup", japanese: "空き教室検索", korean: "빈 강의실 조회", localeIdentifier: localeIdentifier),
                mockLocalizedText(simplifiedChinese: "校园网套餐续费", traditionalChinese: "校園網套餐續費", english: "Campus network renewal", japanese: "学内ネット更新", korean: "캠퍼스 네트워크 갱신", localeIdentifier: localeIdentifier)
            ],
            campusBannerTitle: mockLocalizedText(
                simplifiedChinese: "本周校园资讯：春季招聘双选会将于周三在体育馆举办",
                traditionalChinese: "本週校園資訊：春季招聘雙選會將於週三在體育館舉辦",
                english: "Campus update this week: the spring job fair will be held in the gym on Wednesday.",
                japanese: "今週の学内ニュース: 春の就職フェアが水曜日に体育館で開催されます。",
                korean: "이번 주 캠퍼스 소식: 봄 채용 박람회가 수요일 체육관에서 열립니다.",
                localeIdentifier: localeIdentifier
            ),
            trendingTopics: [
                "# " + mockLocalizedText(simplifiedChinese: "期中复习资料互助", traditionalChinese: "期中複習資料互助", english: "Midterm study materials swap", japanese: "中間試験資料シェア", korean: "중간고사 자료 공유", localeIdentifier: localeIdentifier),
                "# " + mockLocalizedText(simplifiedChinese: "校园跑步打卡", traditionalChinese: "校園跑步打卡", english: "Campus running check-in", japanese: "学内ランニング記録", korean: "캠퍼스 러닝 체크인", localeIdentifier: localeIdentifier),
                "# " + mockLocalizedText(simplifiedChinese: "图书馆闭馆时间调整", traditionalChinese: "圖書館閉館時間調整", english: "Library closing hour update", japanese: "図書館閉館時間変更", korean: "도서관 마감 시간 변경", localeIdentifier: localeIdentifier)
            ]
        )
    }

    static var communityHotPosts: [CommunityPost] { [
        CommunityPost(
            id: "post_hot_001",
            authorName: localizedString("mock.community.hot1.authorName"),
            authorAvatarURL: "https://example.com/avatar/club_cs.png",
            isAnonymous: false,
            createdAt: localizedString("mock.community.hot1.createdAt"),
            title: localizedString("mock.community.hot1.title"),
            summary: localizedString("mock.community.hot1.summary"),
            tags: [localizedString("mock.community.tag.techExchange"), localizedString("mock.community.tag.clubActivity")],
            likeCount: 126,
            commentCount: 38
        ),
        CommunityPost(
            id: "post_hot_002",
            authorName: localizedString("mock.community.hot2.authorName"),
            authorAvatarURL: "",
            isAnonymous: true,
            createdAt: localizedString("mock.community.hot2.createdAt"),
            title: localizedString("mock.community.hot2.title"),
            summary: localizedString("mock.community.hot2.summary"),
            tags: [localizedString("mock.community.tag.studyHelp"), localizedString("mock.community.tag.courseDiscussion")],
            likeCount: 89,
            commentCount: 52
        ),
        CommunityPost(
            id: "post_hot_003",
            authorName: localizedString("mock.community.hot3.authorName"),
            authorAvatarURL: "https://example.com/avatar/student_union.png",
            isAnonymous: false,
            createdAt: localizedString("mock.community.hot3.createdAt"),
            title: localizedString("mock.community.hot3.title"),
            summary: localizedString("mock.community.hot3.summary"),
            tags: [localizedString("mock.community.tag.campusEvent"), localizedString("mock.community.tag.volunteer")],
            likeCount: 160,
            commentCount: 21
        )
    ] }

    static var communityLatestPosts: [CommunityPost] { [
        CommunityPost(
            id: "post_latest_001",
            authorName: localizedString("mock.community.latest1.authorName"),
            authorAvatarURL: "https://example.com/avatar/english_club.png",
            isAnonymous: false,
            createdAt: localizedString("mock.community.latest1.createdAt"),
            title: localizedString("mock.community.latest1.title"),
            summary: localizedString("mock.community.latest1.summary"),
            tags: [localizedString("mock.community.tag.studyAbroad"), localizedString("mock.community.tag.lecture")],
            likeCount: 8,
            commentCount: 2
        ),
        CommunityPost(
            id: "post_latest_002",
            authorName: localizedString("mock.community.latest2.authorName"),
            authorAvatarURL: "",
            isAnonymous: true,
            createdAt: localizedString("mock.community.latest2.createdAt"),
            title: localizedString("mock.community.latest2.title"),
            summary: localizedString("mock.community.latest2.summary"),
            tags: [localizedString("mock.community.tag.campusLife"), localizedString("mock.community.tag.canteen")],
            likeCount: 12,
            commentCount: 7
        ),
        CommunityPost(
            id: "post_latest_003",
            authorName: localizedString("mock.community.latest3.authorName"),
            authorAvatarURL: "https://example.com/avatar/library.png",
            isAnonymous: false,
            createdAt: localizedString("mock.community.latest3.createdAt"),
            title: localizedString("mock.community.latest3.title"),
            summary: localizedString("mock.community.latest3.summary"),
            tags: [localizedString("mock.community.tag.announcement"), localizedString("mock.community.tag.library")],
            likeCount: 24,
            commentCount: 5
        )
    ] }

    static var communityCommentsByPostID: [String: [CommunityComment]] { [
        "post_hot_001": [
            CommunityComment(
                id: "comment_hot_001",
                authorName: localizedString("mock.community.commentHot1.authorName"),
                isAnonymous: false,
                createdAt: localizedString("mock.community.commentHot1.createdAt"),
                content: localizedString("mock.community.commentHot1.content"),
                likeCount: 12
            ),
            CommunityComment(
                id: "comment_hot_002",
                authorName: localizedString("mock.community.commentHot2.authorName"),
                isAnonymous: true,
                createdAt: localizedString("mock.community.commentHot2.createdAt"),
                content: localizedString("mock.community.commentHot2.content"),
                likeCount: 7
            )
        ],
        "post_hot_002": [
            CommunityComment(
                id: "comment_hot_003",
                authorName: localizedString("mock.community.commentHot3.authorName"),
                isAnonymous: false,
                createdAt: localizedString("mock.community.commentHot3.createdAt"),
                content: localizedString("mock.community.commentHot3.content"),
                likeCount: 15
            )
        ],
        "post_latest_001": [
            CommunityComment(
                id: "comment_latest_001",
                authorName: localizedString("mock.community.commentLatest1.authorName"),
                isAnonymous: false,
                createdAt: localizedString("mock.community.commentLatest1.createdAt"),
                content: localizedString("mock.community.commentLatest1.content"),
                likeCount: 3
            )
        ]
    ] }

    static func communityTopic(topicID: String) -> CommunityTopic {
        let tagTechExchange = localizedString("mock.community.tag.techExchange")
        let tagClubActivity = localizedString("mock.community.tag.clubActivity")
        let tagStudyHelp = localizedString("mock.community.tag.studyHelp")
        let tagCourseDiscussion = localizedString("mock.community.tag.courseDiscussion")
        let tagCampusEvent = localizedString("mock.community.tag.campusEvent")
        let tagVolunteer = localizedString("mock.community.tag.volunteer")
        let tagStudyAbroad = localizedString("mock.community.tag.studyAbroad")
        let tagLecture = localizedString("mock.community.tag.lecture")
        let tagCampusLife = localizedString("mock.community.tag.campusLife")
        let tagCanteen = localizedString("mock.community.tag.canteen")
        let tagAnnouncement = localizedString("mock.community.tag.announcement")
        let tagLibrary = localizedString("mock.community.tag.library")

        switch topicID {
        case tagTechExchange:
            return CommunityTopic(id: topicID, title: "#\(tagTechExchange)", summary: localizedString("mock.community.topicSummary.techExchange"))
        case tagClubActivity:
            return CommunityTopic(id: topicID, title: "#\(tagClubActivity)", summary: localizedString("mock.community.topicSummary.clubActivity"))
        case tagStudyHelp:
            return CommunityTopic(id: topicID, title: "#\(tagStudyHelp)", summary: localizedString("mock.community.topicSummary.studyHelp"))
        case tagCourseDiscussion:
            return CommunityTopic(id: topicID, title: "#\(tagCourseDiscussion)", summary: localizedString("mock.community.topicSummary.courseDiscussion"))
        case tagCampusEvent:
            return CommunityTopic(id: topicID, title: "#\(tagCampusEvent)", summary: localizedString("mock.community.topicSummary.campusEvent"))
        case tagVolunteer:
            return CommunityTopic(id: topicID, title: "#\(tagVolunteer)", summary: localizedString("mock.community.topicSummary.volunteer"))
        case tagStudyAbroad:
            return CommunityTopic(id: topicID, title: "#\(tagStudyAbroad)", summary: localizedString("mock.community.topicSummary.studyAbroad"))
        case tagLecture:
            return CommunityTopic(id: topicID, title: "#\(tagLecture)", summary: localizedString("mock.community.topicSummary.lecture"))
        case tagCampusLife:
            return CommunityTopic(id: topicID, title: "#\(tagCampusLife)", summary: localizedString("mock.community.topicSummary.campusLife"))
        case tagCanteen:
            return CommunityTopic(id: topicID, title: "#\(tagCanteen)", summary: localizedString("mock.community.topicSummary.canteen"))
        case tagAnnouncement:
            return CommunityTopic(id: topicID, title: "#\(tagAnnouncement)", summary: localizedString("mock.community.topicSummary.announcement"))
        case tagLibrary:
            return CommunityTopic(id: topicID, title: "#\(tagLibrary)", summary: localizedString("mock.community.topicSummary.library"))
        default:
            return CommunityTopic(id: topicID, title: "#\(topicID)", summary: localizedString("mock.community.topicSummary.default"))
        }
    }

    static func communityPostContent(postID: String) -> String {
        switch postID {
        case "post_hot_001":
            return localizedString("mock.community.content.hot1")
        case "post_hot_002":
            return localizedString("mock.community.content.hot2")
        case "post_hot_003":
            return localizedString("mock.community.content.hot3")
        case "post_latest_001":
            return localizedString("mock.community.content.latest1")
        case "post_latest_002":
            return localizedString("mock.community.content.latest2")
        case "post_latest_003":
            return localizedString("mock.community.content.latest3")
        default:
            return localizedString("mock.community.content.default")
        }
    }

    static func weeklySchedule(weekIndex: Int) -> WeeklySchedule {
        let localeIdentifier = AppLanguage.currentIdentifier()

        return WeeklySchedule(
            weekIndex: weekIndex,
            termName: mockLocalizedText(
                simplifiedChinese: "2025-2026 学年第二学期",
                traditionalChinese: "2025-2026 學年第二學期",
                english: "AY 2025-2026 Semester 2",
                japanese: "2025-2026年度 第2学期",
                korean: "2025-2026학년도 2학기",
                localeIdentifier: localeIdentifier
            ),
            days: [
                CourseDaySection(
                    dayOfWeek: 1,
                    dayTitle: mockLocalizedText(simplifiedChinese: "周一", traditionalChinese: "週一", english: "Mon", japanese: "月", korean: "월", localeIdentifier: localeIdentifier),
                    dateText: "03/09",
                    courses: [
                        CourseItem(
                            id: "course_monday_1",
                            courseName: mockLocalizedText(simplifiedChinese: "高等数学 A2", traditionalChinese: "高等數學 A2", english: "Advanced Mathematics A2", japanese: "高等数学 A2", korean: "고등수학 A2", localeIdentifier: localeIdentifier),
                            teacherName: mockLocalizedText(simplifiedChinese: "王老师", traditionalChinese: "王老師", english: "Prof. Wang", japanese: "王先生", korean: "왕 교수", localeIdentifier: localeIdentifier),
                            location: mockLocalizedText(simplifiedChinese: "教学楼 A301", traditionalChinese: "教學樓 A301", english: "Teaching Building A301", japanese: "講義棟 A301", korean: "강의동 A301", localeIdentifier: localeIdentifier),
                            dayOfWeek: 1,
                            startSection: 1,
                            endSection: 2,
                            weekIndices: Array(1...16)
                        ),
                        CourseItem(
                            id: "course_monday_2",
                            courseName: mockLocalizedText(simplifiedChinese: "移动应用开发", traditionalChinese: "移動應用開發", english: "Mobile App Development", japanese: "モバイルアプリ開発", korean: "모바일 앱 개발", localeIdentifier: localeIdentifier),
                            teacherName: mockLocalizedText(simplifiedChinese: "李老师", traditionalChinese: "李老師", english: "Prof. Li", japanese: "李先生", korean: "이 교수", localeIdentifier: localeIdentifier),
                            location: mockLocalizedText(simplifiedChinese: "实验楼 B204", traditionalChinese: "實驗樓 B204", english: "Lab Building B204", japanese: "実験棟 B204", korean: "실험동 B204", localeIdentifier: localeIdentifier),
                            dayOfWeek: 1,
                            startSection: 7,
                            endSection: 8,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(
                    dayOfWeek: 2,
                    dayTitle: mockLocalizedText(simplifiedChinese: "周二", traditionalChinese: "週二", english: "Tue", japanese: "火", korean: "화", localeIdentifier: localeIdentifier),
                    dateText: "03/10",
                    courses: [
                        CourseItem(
                            id: "course_tuesday_1",
                            courseName: mockLocalizedText(simplifiedChinese: "大学英语", traditionalChinese: "大學英語", english: "College English", japanese: "大学英語", korean: "대학 영어", localeIdentifier: localeIdentifier),
                            teacherName: mockLocalizedText(simplifiedChinese: "陈老师", traditionalChinese: "陳老師", english: "Prof. Chen", japanese: "陳先生", korean: "천 교수", localeIdentifier: localeIdentifier),
                            location: mockLocalizedText(simplifiedChinese: "教学楼 C102", traditionalChinese: "教學樓 C102", english: "Teaching Building C102", japanese: "講義棟 C102", korean: "강의동 C102", localeIdentifier: localeIdentifier),
                            dayOfWeek: 2,
                            startSection: 3,
                            endSection: 4,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(
                    dayOfWeek: 3,
                    dayTitle: mockLocalizedText(simplifiedChinese: "周三", traditionalChinese: "週三", english: "Wed", japanese: "水", korean: "수", localeIdentifier: localeIdentifier),
                    dateText: "03/11",
                    courses: [
                        CourseItem(
                            id: "course_wednesday_1",
                            courseName: mockLocalizedText(simplifiedChinese: "数据库系统", traditionalChinese: "資料庫系統", english: "Database Systems", japanese: "データベースシステム", korean: "데이터베이스 시스템", localeIdentifier: localeIdentifier),
                            teacherName: mockLocalizedText(simplifiedChinese: "赵老师", traditionalChinese: "趙老師", english: "Prof. Zhao", japanese: "趙先生", korean: "조 교수", localeIdentifier: localeIdentifier),
                            location: mockLocalizedText(simplifiedChinese: "教学楼 A207", traditionalChinese: "教學樓 A207", english: "Teaching Building A207", japanese: "講義棟 A207", korean: "강의동 A207", localeIdentifier: localeIdentifier),
                            dayOfWeek: 3,
                            startSection: 1,
                            endSection: 2,
                            weekIndices: Array(1...16)
                        ),
                        CourseItem(
                            id: "course_wednesday_2",
                            courseName: mockLocalizedText(simplifiedChinese: "体育", traditionalChinese: "體育", english: "Physical Education", japanese: "体育", korean: "체육", localeIdentifier: localeIdentifier),
                            teacherName: mockLocalizedText(simplifiedChinese: "周老师", traditionalChinese: "周老師", english: "Prof. Zhou", japanese: "周先生", korean: "주 교수", localeIdentifier: localeIdentifier),
                            location: mockLocalizedText(simplifiedChinese: "体育馆 2 号场", traditionalChinese: "體育館 2 號場", english: "Gym Court 2", japanese: "体育館 2番コート", korean: "체육관 2번 코트", localeIdentifier: localeIdentifier),
                            dayOfWeek: 3,
                            startSection: 9,
                            endSection: 10,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(
                    dayOfWeek: 4,
                    dayTitle: mockLocalizedText(simplifiedChinese: "周四", traditionalChinese: "週四", english: "Thu", japanese: "木", korean: "목", localeIdentifier: localeIdentifier),
                    dateText: "03/12",
                    courses: [
                        CourseItem(
                            id: "course_thursday_1",
                            courseName: mockLocalizedText(simplifiedChinese: "计算机网络", traditionalChinese: "計算機網路", english: "Computer Networks", japanese: "コンピュータネットワーク", korean: "컴퓨터 네트워크", localeIdentifier: localeIdentifier),
                            teacherName: mockLocalizedText(simplifiedChinese: "孙老师", traditionalChinese: "孫老師", english: "Prof. Sun", japanese: "孫先生", korean: "손 교수", localeIdentifier: localeIdentifier),
                            location: mockLocalizedText(simplifiedChinese: "教学楼 D308", traditionalChinese: "教學樓 D308", english: "Teaching Building D308", japanese: "講義棟 D308", korean: "강의동 D308", localeIdentifier: localeIdentifier),
                            dayOfWeek: 4,
                            startSection: 5,
                            endSection: 6,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(
                    dayOfWeek: 5,
                    dayTitle: mockLocalizedText(simplifiedChinese: "周五", traditionalChinese: "週五", english: "Fri", japanese: "金", korean: "금", localeIdentifier: localeIdentifier),
                    dateText: "03/13",
                    courses: [
                        CourseItem(
                            id: "course_friday_1",
                            courseName: mockLocalizedText(simplifiedChinese: "软件工程导论", traditionalChinese: "軟體工程導論", english: "Introduction to Software Engineering", japanese: "ソフトウェア工学入門", korean: "소프트웨어 공학 입문", localeIdentifier: localeIdentifier),
                            teacherName: mockLocalizedText(simplifiedChinese: "吴老师", traditionalChinese: "吳老師", english: "Prof. Wu", japanese: "呉先生", korean: "오 교수", localeIdentifier: localeIdentifier),
                            location: mockLocalizedText(simplifiedChinese: "教学楼 A105", traditionalChinese: "教學樓 A105", english: "Teaching Building A105", japanese: "講義棟 A105", korean: "강의동 A105", localeIdentifier: localeIdentifier),
                            dayOfWeek: 5,
                            startSection: 1,
                            endSection: 2,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(dayOfWeek: 6, dayTitle: mockLocalizedText(simplifiedChinese: "周六", traditionalChinese: "週六", english: "Sat", japanese: "土", korean: "토", localeIdentifier: localeIdentifier), dateText: "03/14", courses: []),
                CourseDaySection(dayOfWeek: 7, dayTitle: mockLocalizedText(simplifiedChinese: "周日", traditionalChinese: "週日", english: "Sun", japanese: "日", korean: "일", localeIdentifier: localeIdentifier), dateText: "03/15", courses: [])
            ]
        )
    }

    static let academicYears: [AcademicYearOption] = [
        AcademicYearOption(id: "2025-2026", title: "2025-2026"),
        AcademicYearOption(id: "2024-2025", title: "2024-2025"),
        AcademicYearOption(id: "2023-2024", title: "2023-2024"),
        AcademicYearOption(id: "2022-2023", title: "2022-2023")
    ]

    static func gradeReport(academicYear: String) -> GradeReport {
        let localeIdentifier = AppLanguage.currentIdentifier()
        let selected = academicYears.map(\.id).contains(academicYear) ? academicYear : "2025-2026"

        if selected == "2024-2025" {
            return GradeReport(
                selectedYear: selected,
                yearOptions: academicYears,
                summary: GradeSummary(gpa: 3.54, averageScore: 85.6, earnedCredits: 39.0, totalCredits: 42.0),
                terms: [
                    GradeTermReport(
                        id: "1",
                        title: mockLocalizedText(simplifiedChinese: "第一学期", traditionalChinese: "第一學期", english: "Semester 1", japanese: "第1学期", korean: "1학기", localeIdentifier: localeIdentifier),
                        gpa: 3.50,
                        items: [
                            GradeItem(id: "grade_2425_01", courseName: mockLocalizedText(simplifiedChinese: "数据结构", traditionalChinese: "資料結構", english: "Data Structures", japanese: "データ構造", korean: "자료구조", localeIdentifier: localeIdentifier), courseType: mockLocalizedText(simplifiedChinese: "必修", traditionalChinese: "必修", english: "Required", japanese: "必修", korean: "필수", localeIdentifier: localeIdentifier), credit: 4.0, score: 88.0, gradePoint: 3.8, term: "2024-2025-1"),
                            GradeItem(id: "grade_2425_02", courseName: mockLocalizedText(simplifiedChinese: "离散数学", traditionalChinese: "離散數學", english: "Discrete Mathematics", japanese: "離散数学", korean: "이산수학", localeIdentifier: localeIdentifier), courseType: mockLocalizedText(simplifiedChinese: "必修", traditionalChinese: "必修", english: "Required", japanese: "必修", korean: "필수", localeIdentifier: localeIdentifier), credit: 3.0, score: 82.0, gradePoint: 3.2, term: "2024-2025-1")
                        ]
                    ),
                    GradeTermReport(
                        id: "2",
                        title: mockLocalizedText(simplifiedChinese: "第二学期", traditionalChinese: "第二學期", english: "Semester 2", japanese: "第2学期", korean: "2학기", localeIdentifier: localeIdentifier),
                        gpa: 3.60,
                        items: [
                            GradeItem(id: "grade_2425_03", courseName: mockLocalizedText(simplifiedChinese: "计算机组成原理", traditionalChinese: "計算機組成原理", english: "Computer Organization", japanese: "コンピュータ構成原理", korean: "컴퓨터 구조", localeIdentifier: localeIdentifier), courseType: mockLocalizedText(simplifiedChinese: "必修", traditionalChinese: "必修", english: "Required", japanese: "必修", korean: "필수", localeIdentifier: localeIdentifier), credit: 3.5, score: 86.0, gradePoint: 3.6, term: "2024-2025-2")
                        ]
                    )
                ]
            )
        }

        if selected == "2023-2024" {
            return GradeReport(
                selectedYear: selected,
                yearOptions: academicYears,
                summary: GradeSummary(gpa: 3.31, averageScore: 83.2, earnedCredits: 32.0, totalCredits: 34.0),
                terms: [
                    GradeTermReport(
                        id: "1",
                        title: mockLocalizedText(simplifiedChinese: "第一学期", traditionalChinese: "第一學期", english: "Semester 1", japanese: "第1学期", korean: "1학기", localeIdentifier: localeIdentifier),
                        gpa: 3.10,
                        items: [
                            GradeItem(id: "grade_2324_01", courseName: mockLocalizedText(simplifiedChinese: "程序设计基础", traditionalChinese: "程式設計基礎", english: "Programming Fundamentals", japanese: "プログラミング基礎", korean: "프로그래밍 기초", localeIdentifier: localeIdentifier), courseType: mockLocalizedText(simplifiedChinese: "必修", traditionalChinese: "必修", english: "Required", japanese: "必修", korean: "필수", localeIdentifier: localeIdentifier), credit: 4.0, score: 84.0, gradePoint: 3.4, term: "2023-2024-1"),
                            GradeItem(id: "grade_2324_02", courseName: mockLocalizedText(simplifiedChinese: "高等数学 A1", traditionalChinese: "高等數學 A1", english: "Advanced Mathematics A1", japanese: "高等数学 A1", korean: "고등수학 A1", localeIdentifier: localeIdentifier), courseType: mockLocalizedText(simplifiedChinese: "必修", traditionalChinese: "必修", english: "Required", japanese: "必修", korean: "필수", localeIdentifier: localeIdentifier), credit: 5.0, score: 79.0, gradePoint: 2.9, term: "2023-2024-1")
                        ]
                    ),
                    GradeTermReport(
                        id: "2",
                        title: mockLocalizedText(simplifiedChinese: "第二学期", traditionalChinese: "第二學期", english: "Semester 2", japanese: "第2学期", korean: "2학기", localeIdentifier: localeIdentifier),
                        gpa: 3.50,
                        items: [
                            GradeItem(id: "grade_2324_03", courseName: mockLocalizedText(simplifiedChinese: "大学物理", traditionalChinese: "大學物理", english: "College Physics", japanese: "大学物理", korean: "대학 물리", localeIdentifier: localeIdentifier), courseType: mockLocalizedText(simplifiedChinese: "必修", traditionalChinese: "必修", english: "Required", japanese: "必修", korean: "필수", localeIdentifier: localeIdentifier), credit: 3.0, score: 85.0, gradePoint: 3.5, term: "2023-2024-2")
                        ]
                    )
                ]
            )
        }

        return GradeReport(
            selectedYear: "2025-2026",
            yearOptions: academicYears,
            summary: GradeSummary(gpa: 3.68, averageScore: 88.7, earnedCredits: 21.5, totalCredits: 22.0),
            terms: [
                GradeTermReport(
                    id: "1",
                    title: mockLocalizedText(simplifiedChinese: "第一学期", traditionalChinese: "第一學期", english: "Semester 1", japanese: "第1学期", korean: "1학기", localeIdentifier: localeIdentifier),
                    gpa: 3.68,
                    items: [
                        GradeItem(id: "grade_2526_01", courseName: mockLocalizedText(simplifiedChinese: "移动应用开发", traditionalChinese: "移動應用開發", english: "Mobile App Development", japanese: "モバイルアプリ開発", korean: "모바일 앱 개발", localeIdentifier: localeIdentifier), courseType: mockLocalizedText(simplifiedChinese: "必修", traditionalChinese: "必修", english: "Required", japanese: "必修", korean: "필수", localeIdentifier: localeIdentifier), credit: 3.0, score: 92.0, gradePoint: 4.0, term: "2025-2026-1"),
                        GradeItem(id: "grade_2526_02", courseName: mockLocalizedText(simplifiedChinese: "操作系统", traditionalChinese: "作業系統", english: "Operating Systems", japanese: "オペレーティングシステム", korean: "운영체제", localeIdentifier: localeIdentifier), courseType: mockLocalizedText(simplifiedChinese: "必修", traditionalChinese: "必修", english: "Required", japanese: "必修", korean: "필수", localeIdentifier: localeIdentifier), credit: 3.5, score: 87.0, gradePoint: 3.7, term: "2025-2026-1"),
                        GradeItem(id: "grade_2526_03", courseName: mockLocalizedText(simplifiedChinese: "软件测试", traditionalChinese: "軟體測試", english: "Software Testing", japanese: "ソフトウェアテスト", korean: "소프트웨어 테스트", localeIdentifier: localeIdentifier), courseType: mockLocalizedText(simplifiedChinese: "选修", traditionalChinese: "選修", english: "Elective", japanese: "選択", korean: "선택", localeIdentifier: localeIdentifier), credit: 2.0, score: 89.0, gradePoint: 3.9, term: "2025-2026-1")
                    ]
                ),
                GradeTermReport(
                    id: "2",
                    title: mockLocalizedText(simplifiedChinese: "第二学期", traditionalChinese: "第二學期", english: "Semester 2", japanese: "第2学期", korean: "2학기", localeIdentifier: localeIdentifier),
                    gpa: 0,
                    items: []
                )
            ]
        )
    }

    static func cardDashboard(isLoss: Bool, queryDate: Date) -> CampusCardDashboard {
        let status: CardStatus = isLoss ? .lost : .normal
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.locale(for: UserPreferences.currentLocale)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let calendar = Calendar(identifier: .gregorian)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: queryDate) ?? queryDate
        let queryDayPrefix = String(formatter.string(from: queryDate).prefix(10))
        let localeIdentifier = AppLanguage.currentIdentifier()

        let transactions = [
            CardTransaction(id: "card_tx_001", timeText: "\(String(formatter.string(from: queryDate).prefix(10))) 12:12", merchantName: mockLocalizedText(simplifiedChinese: "北区食堂二楼", traditionalChinese: "北區食堂二樓", english: "North Canteen 2F", japanese: "北区食堂 2階", korean: "북구 식당 2층", localeIdentifier: localeIdentifier), amount: 15.50, category: mockLocalizedText(simplifiedChinese: "餐饮", traditionalChinese: "餐飲", english: "Dining", japanese: "食事", korean: "식비", localeIdentifier: localeIdentifier)),
            CardTransaction(id: "card_tx_002", timeText: "\(String(formatter.string(from: queryDate).prefix(10))) 08:06", merchantName: mockLocalizedText(simplifiedChinese: "校园超市", traditionalChinese: "校園超市", english: "Campus Store", japanese: "学内コンビニ", korean: "캠퍼스 매점", localeIdentifier: localeIdentifier), amount: 23.80, category: mockLocalizedText(simplifiedChinese: "购物", traditionalChinese: "購物", english: "Shopping", japanese: "買い物", korean: "쇼핑", localeIdentifier: localeIdentifier)),
            CardTransaction(id: "card_tx_003", timeText: "\(String(formatter.string(from: previousDay).prefix(10))) 18:32", merchantName: mockLocalizedText(simplifiedChinese: "图书馆打印中心", traditionalChinese: "圖書館打印中心", english: "Library Print Center", japanese: "図書館プリントセンター", korean: "도서관 프린트 센터", localeIdentifier: localeIdentifier), amount: 4.00, category: mockLocalizedText(simplifiedChinese: "打印", traditionalChinese: "打印", english: "Printing", japanese: "印刷", korean: "인쇄", localeIdentifier: localeIdentifier))
        ].filter { $0.timeText.hasPrefix(queryDayPrefix) }

        return CampusCardDashboard(
            info: CampusCardInfo(
                cardNumber: "6214 88** **** 1024",
                ownerName: mockLocalizedText(simplifiedChinese: "林知远", traditionalChinese: "林知遠", english: "Lin Zhiyuan", japanese: "リン・ジーユエン", korean: "린즈위안", localeIdentifier: localeIdentifier),
                balance: isLoss ? 0 : 128.45,
                status: status,
                lastUpdated: mockLocalizedText(simplifiedChinese: "今天 12:34", traditionalChinese: "今天 12:34", english: "Today 12:34", japanese: "今日 12:34", korean: "오늘 12:34", localeIdentifier: localeIdentifier)
            ),
            transactions: transactions
        )
    }

    static var libraryBooks: [LibraryBook] { [
        LibraryBook(id: "book_001", title: localizedString("mock.library.book1.title"), author: localizedString("mock.library.book1.author"), availableCount: 3, location: localizedString("mock.library.book1.location")),
        LibraryBook(id: "book_002", title: localizedString("mock.library.book2.title"), author: "Aditya Bhargava", availableCount: 1, location: localizedString("mock.library.book2.location")),
        LibraryBook(id: "book_003", title: localizedString("mock.library.book3.title"), author: localizedString("mock.library.book3.author"), availableCount: 0, location: localizedString("mock.library.book3.location")),
        LibraryBook(id: "book_004", title: localizedString("mock.library.book4.title"), author: "Kurose", availableCount: 2, location: localizedString("mock.library.book4.location"))
    ] }

    static func libraryBookDetail(bookID: String) -> LibraryBookDetail {
        if bookID == "book_002" {
            return LibraryBookDetail(
                id: "book_002",
                title: localizedString("mock.library.book2.title"),
                author: "Aditya Bhargava",
                publisher: localizedString("mock.library.book2.publisher"),
                isbn: "9787115447637",
                summary: localizedString("mock.library.book2.summary"),
                availableCount: 1,
                location: localizedString("mock.library.book2.location")
            )
        }

        if bookID == "book_003" {
            return LibraryBookDetail(
                id: "book_003",
                title: localizedString("mock.library.book3.title"),
                author: localizedString("mock.library.book3.author"),
                publisher: localizedString("mock.library.book3.publisher"),
                isbn: "9787040587446",
                summary: localizedString("mock.library.book3.summary"),
                availableCount: 0,
                location: localizedString("mock.library.book3.location")
            )
        }

        if bookID == "book_004" {
            return LibraryBookDetail(
                id: "book_004",
                title: localizedString("mock.library.book4.title"),
                author: "Kurose",
                publisher: localizedString("mock.library.book4.publisher"),
                isbn: "9787111716485",
                summary: localizedString("mock.library.book4.summary"),
                availableCount: 2,
                location: localizedString("mock.library.book4.location")
            )
        }

        return LibraryBookDetail(
            id: "book_001",
            title: localizedString("mock.library.book1.title"),
            author: localizedString("mock.library.book1.author"),
            publisher: localizedString("mock.library.book1.publisher"),
            isbn: "9787121422338",
            summary: localizedString("mock.library.book1.summary"),
            availableCount: 3,
            location: localizedString("mock.library.book1.location")
        )
    }

    static func borrowRecords(renewedRecordIDs: Set<String>) -> [BorrowRecord] {
        [
            BorrowRecord(
                id: "borrow_001",
                bookTitle: localizedString("mock.library.book3.title"),
                borrowDate: "2026-02-20",
                dueDate: renewedRecordIDs.contains("borrow_001") ? "2026-04-06" : "2026-03-23",
                status: renewedRecordIDs.contains("borrow_001") ? localizedString("mock.library.borrow.renewedOnce") : localizedString("mock.library.borrow.borrowing"),
                renewable: !renewedRecordIDs.contains("borrow_001"),
                sn: "borrow_001",
                code: "code_001"
            ),
            BorrowRecord(
                id: "borrow_002",
                bookTitle: localizedString("mock.library.book4.title"),
                borrowDate: "2026-02-28",
                dueDate: "2026-03-31",
                status: localizedString("mock.library.borrow.borrowing"),
                renewable: true,
                sn: "borrow_002",
                code: "code_002"
            )
        ]
    }

    static var cetDashboard: CETDashboard {
        CETDashboard(
            profile: CETProfile(
                candidateName: localizedString("mock.cet.seed.candidateName"),
                schoolName: localizedString("mock.cet.seed.schoolName"),
                examLevel: "CET-6",
                admissionTicket: "440120260601234",
                examDate: "2026-06-15 09:00",
                examVenue: localizedString("mock.cet.seed.examVenue")
            ),
            scoreRecords: [
                CETScoreRecord(
                    id: "cet_2025_12",
                    examSession: localizedString("mock.cet.seed.session202512"),
                    level: "CET-6",
                    totalScore: 532,
                    listeningScore: 182,
                    readingScore: 198,
                    writingScore: 152,
                    speakingScore: nil,
                    passed: true
                ),
                CETScoreRecord(
                    id: "cet_2025_06",
                    examSession: localizedString("mock.cet.seed.session202506"),
                    level: "CET-4",
                    totalScore: 578,
                    listeningScore: 196,
                    readingScore: 215,
                    writingScore: 167,
                    speakingScore: 81,
                    passed: true
                )
            ]
        )
    }
}

private func localizedMockLocation(_ localeIdentifier: String) -> ProfileLocationSelection {
    ProfileLocationSelection(
        displayName: localizedMockProfileText(
            simplifiedChinese: "中国 广东省 广州市",
            traditionalChinese: "中國 廣東省 廣州市",
            english: "China Guangdong Province Guangzhou",
            japanese: "中国 広東省 広州市",
            korean: "중국 광둥성 광저우시",
            localeIdentifier: localeIdentifier
        ),
        regionCode: "CN",
        stateCode: "44",
        cityCode: "1"
    )
}

private func localizedMockHometown(_ localeIdentifier: String) -> ProfileLocationSelection {
    ProfileLocationSelection(
        displayName: localizedMockProfileText(
            simplifiedChinese: "中国 广东省 汕头市",
            traditionalChinese: "中國 廣東省 汕頭市",
            english: "China Guangdong Province Shantou",
            japanese: "中国 広東省 汕頭市",
            korean: "중국 광둥성 산터우시",
            localeIdentifier: localeIdentifier
        ),
        regionCode: "CN",
        stateCode: "44",
        cityCode: "5"
    )
}

private func localizedMockProfileText(
    simplifiedChinese: String,
    traditionalChinese: String,
    english: String,
    japanese: String,
    korean: String,
    localeIdentifier: String
) -> String {
    mockLocalizedText(
        simplifiedChinese: simplifiedChinese,
        traditionalChinese: traditionalChinese,
        english: english,
        japanese: japanese,
        korean: korean,
        localeIdentifier: localeIdentifier
    )
}

func mockLocalizedText(
    simplifiedChinese: String,
    traditionalChinese: String,
    english: String,
    japanese: String,
    korean: String,
    localeIdentifier: String? = nil
) -> String {
    let resolvedLocale = localeIdentifier ?? AppLanguage.currentIdentifier()

    switch AppLanguage.normalizedIdentifier(from: resolvedLocale) {
    case "zh-HK", "zh-TW":
        return traditionalChinese
    case "en":
        return english
    case "ja":
        return japanese
    case "ko":
        return korean
    default:
        return simplifiedChinese
    }
}

extension MockSeedData {
    static let cetCaptchaBase64 = "iVBORw0KGgoAAAANSUhEUgAAAMAAAAA8CAIAAACVO0mNAAAA/0lEQVR4nO3TsQ3DMBQFQdP9d7aBkYzWxExA0RduCMsZ/HXXIQK5vCk1vZ1tc665fb3e8DqgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJoCaAmoCqAmgJqBv+B8C9ZV8o8AAAAASUVORK5CYII="

    static func cetDashboard(ticketNumber: String, candidateName: String) -> CETDashboard {
        CETDashboard(
            profile: CETProfile(
                candidateName: candidateName,
                schoolName: cetDashboard.profile.schoolName,
                examLevel: cetDashboard.profile.examLevel,
                admissionTicket: ticketNumber,
                examDate: cetDashboard.profile.examDate,
                examVenue: cetDashboard.profile.examVenue
            ),
            scoreRecords: cetDashboard.scoreRecords
        )
    }
}
