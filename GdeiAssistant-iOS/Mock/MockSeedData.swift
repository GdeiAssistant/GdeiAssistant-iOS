import Foundation

enum MockSeedData {
    static let demoProfile = UserProfile(
        id: "u_gdeiassistant",
        username: "gdeiassistant",
        nickname: "林知远",
        avatarURL: "https://example.com/avatar/student.png",
        college: "计算机科学系",
        major: "软件工程",
        grade: "2023",
        bio: "喜欢做实用的小工具，也在准备 iOS 开发实习。",
        birthday: "2004-09-16",
        location: "中国 广东省 广州市",
        hometown: "中国 广东省 汕头市",
        ipArea: "广东"
    )

    static let dashboard = HomeDashboard(
        greeting: "早上好，林知远",
        reminderText: "今天 14:00 在教学楼 A201 有《移动应用开发》实验课，记得提前 10 分钟到教室。",
        quickActions: [
            HomeQuickAction(id: "schedule", title: "课表", icon: "calendar"),
            HomeQuickAction(id: "score", title: "成绩", icon: "chart.bar"),
            HomeQuickAction(id: "campus_card", title: "校园卡", icon: "creditcard"),
            HomeQuickAction(id: "library", title: "图书馆", icon: "books.vertical"),
            HomeQuickAction(id: "cet", title: "四六级", icon: "doc.text.magnifyingglass")
        ],
        recentItems: [
            "图书馆座位预约",
            "教学楼空教室查询",
            "校园网套餐续费"
        ],
        campusBannerTitle: "本周校园资讯：春季招聘双选会将于周三在体育馆举办",
        trendingTopics: [
            "# 期中复习资料互助",
            "# 校园跑步打卡",
            "# 图书馆闭馆时间调整"
        ]
    )

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
        WeeklySchedule(
            weekIndex: weekIndex,
            termName: "2025-2026 学年第二学期",
            days: [
                CourseDaySection(
                    dayOfWeek: 1,
                    dayTitle: "周一",
                    dateText: "03/09",
                    courses: [
                        CourseItem(
                            id: "course_monday_1",
                            courseName: "高等数学 A2",
                            teacherName: "王老师",
                            location: "教学楼 A301",
                            dayOfWeek: 1,
                            startSection: 1,
                            endSection: 2,
                            weekIndices: Array(1...16)
                        ),
                        CourseItem(
                            id: "course_monday_2",
                            courseName: "移动应用开发",
                            teacherName: "李老师",
                            location: "实验楼 B204",
                            dayOfWeek: 1,
                            startSection: 7,
                            endSection: 8,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(
                    dayOfWeek: 2,
                    dayTitle: "周二",
                    dateText: "03/10",
                    courses: [
                        CourseItem(
                            id: "course_tuesday_1",
                            courseName: "大学英语",
                            teacherName: "陈老师",
                            location: "教学楼 C102",
                            dayOfWeek: 2,
                            startSection: 3,
                            endSection: 4,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(
                    dayOfWeek: 3,
                    dayTitle: "周三",
                    dateText: "03/11",
                    courses: [
                        CourseItem(
                            id: "course_wednesday_1",
                            courseName: "数据库系统",
                            teacherName: "赵老师",
                            location: "教学楼 A207",
                            dayOfWeek: 3,
                            startSection: 1,
                            endSection: 2,
                            weekIndices: Array(1...16)
                        ),
                        CourseItem(
                            id: "course_wednesday_2",
                            courseName: "体育",
                            teacherName: "周老师",
                            location: "体育馆 2 号场",
                            dayOfWeek: 3,
                            startSection: 9,
                            endSection: 10,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(
                    dayOfWeek: 4,
                    dayTitle: "周四",
                    dateText: "03/12",
                    courses: [
                        CourseItem(
                            id: "course_thursday_1",
                            courseName: "计算机网络",
                            teacherName: "孙老师",
                            location: "教学楼 D308",
                            dayOfWeek: 4,
                            startSection: 5,
                            endSection: 6,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(
                    dayOfWeek: 5,
                    dayTitle: "周五",
                    dateText: "03/13",
                    courses: [
                        CourseItem(
                            id: "course_friday_1",
                            courseName: "软件工程导论",
                            teacherName: "吴老师",
                            location: "教学楼 A105",
                            dayOfWeek: 5,
                            startSection: 1,
                            endSection: 2,
                            weekIndices: Array(1...16)
                        )
                    ]
                ),
                CourseDaySection(dayOfWeek: 6, dayTitle: "周六", dateText: "03/14", courses: []),
                CourseDaySection(dayOfWeek: 7, dayTitle: "周日", dateText: "03/15", courses: [])
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
        let selected = academicYears.map(\.id).contains(academicYear) ? academicYear : "2025-2026"

        if selected == "2024-2025" {
            return GradeReport(
                selectedYear: selected,
                yearOptions: academicYears,
                summary: GradeSummary(gpa: 3.54, averageScore: 85.6, earnedCredits: 39.0, totalCredits: 42.0),
                terms: [
                    GradeTermReport(
                        id: "1",
                        title: "第一学期",
                        gpa: 3.50,
                        items: [
                            GradeItem(id: "grade_2425_01", courseName: "数据结构", courseType: "必修", credit: 4.0, score: 88.0, gradePoint: 3.8, term: "2024-2025-1"),
                            GradeItem(id: "grade_2425_02", courseName: "离散数学", courseType: "必修", credit: 3.0, score: 82.0, gradePoint: 3.2, term: "2024-2025-1")
                        ]
                    ),
                    GradeTermReport(
                        id: "2",
                        title: "第二学期",
                        gpa: 3.60,
                        items: [
                            GradeItem(id: "grade_2425_03", courseName: "计算机组成原理", courseType: "必修", credit: 3.5, score: 86.0, gradePoint: 3.6, term: "2024-2025-2")
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
                        title: "第一学期",
                        gpa: 3.10,
                        items: [
                            GradeItem(id: "grade_2324_01", courseName: "程序设计基础", courseType: "必修", credit: 4.0, score: 84.0, gradePoint: 3.4, term: "2023-2024-1"),
                            GradeItem(id: "grade_2324_02", courseName: "高等数学 A1", courseType: "必修", credit: 5.0, score: 79.0, gradePoint: 2.9, term: "2023-2024-1")
                        ]
                    ),
                    GradeTermReport(
                        id: "2",
                        title: "第二学期",
                        gpa: 3.50,
                        items: [
                            GradeItem(id: "grade_2324_03", courseName: "大学物理", courseType: "必修", credit: 3.0, score: 85.0, gradePoint: 3.5, term: "2023-2024-2")
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
                    title: "第一学期",
                    gpa: 3.68,
                    items: [
                        GradeItem(id: "grade_2526_01", courseName: "移动应用开发", courseType: "必修", credit: 3.0, score: 92.0, gradePoint: 4.0, term: "2025-2026-1"),
                        GradeItem(id: "grade_2526_02", courseName: "操作系统", courseType: "必修", credit: 3.5, score: 87.0, gradePoint: 3.7, term: "2025-2026-1"),
                        GradeItem(id: "grade_2526_03", courseName: "软件测试", courseType: "选修", credit: 2.0, score: 89.0, gradePoint: 3.9, term: "2025-2026-1")
                    ]
                ),
                GradeTermReport(
                    id: "2",
                    title: "第二学期",
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

        let transactions = [
            CardTransaction(id: "card_tx_001", timeText: "\(String(formatter.string(from: queryDate).prefix(10))) 12:12", merchantName: "北区食堂二楼", amount: 15.50, category: "餐饮"),
            CardTransaction(id: "card_tx_002", timeText: "\(String(formatter.string(from: queryDate).prefix(10))) 08:06", merchantName: "校园超市", amount: 23.80, category: "购物"),
            CardTransaction(id: "card_tx_003", timeText: "\(String(formatter.string(from: previousDay).prefix(10))) 18:32", merchantName: "图书馆打印中心", amount: 4.00, category: "打印")
        ].filter { $0.timeText.hasPrefix(queryDayPrefix) }

        return CampusCardDashboard(
            info: CampusCardInfo(
                cardNumber: "6214 88** **** 1024",
                ownerName: "林知远",
                balance: isLoss ? 0 : 128.45,
                status: status,
                lastUpdated: "今天 12:34"
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

extension MockSeedData {
    static let cetCaptchaBase64 = ""

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
