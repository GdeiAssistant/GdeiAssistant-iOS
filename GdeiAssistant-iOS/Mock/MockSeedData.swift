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

    static let communityHotPosts: [CommunityPost] = [
        CommunityPost(
            id: "post_hot_001",
            authorName: "计算机协会",
            authorAvatarURL: "https://example.com/avatar/club_cs.png",
            isAnonymous: false,
            createdAt: "10分钟前",
            title: "下周三晚开设 iOS 入门分享会，欢迎旁听",
            summary: "本次分享覆盖 SwiftUI 基础、项目结构设计和简历项目打磨，活动结束后开放答疑。",
            tags: ["技术交流", "社团活动"],
            likeCount: 126,
            commentCount: 38
        ),
        CommunityPost(
            id: "post_hot_002",
            authorName: "匿名同学",
            authorAvatarURL: "",
            isAnonymous: true,
            createdAt: "35分钟前",
            title: "求推荐数据库课程复习路径",
            summary: "基础一般，时间只有一周，想先抓重点知识点和常考题型，有同学愿意分享笔记吗？",
            tags: ["学习互助", "课程讨论"],
            likeCount: 89,
            commentCount: 52
        ),
        CommunityPost(
            id: "post_hot_003",
            authorName: "校学生会",
            authorAvatarURL: "https://example.com/avatar/student_union.png",
            isAnonymous: false,
            createdAt: "1小时前",
            title: "校园马拉松志愿者报名开始",
            summary: "志愿时长可认定第二课堂学分，岗位包含赛道引导、物资发放、医疗协助。",
            tags: ["校园活动", "志愿服务"],
            likeCount: 160,
            commentCount: 21
        )
    ]

    static let communityLatestPosts: [CommunityPost] = [
        CommunityPost(
            id: "post_latest_001",
            authorName: "英语角负责人",
            authorAvatarURL: "https://example.com/avatar/english_club.png",
            isAnonymous: false,
            createdAt: "刚刚",
            title: "今晚英语角主题：海外交换申请经验",
            summary: "欢迎有申请计划的同学来交流选校策略、文书准备和时间线安排。",
            tags: ["留学交流", "讲座"],
            likeCount: 8,
            commentCount: 2
        ),
        CommunityPost(
            id: "post_latest_002",
            authorName: "匿名同学",
            authorAvatarURL: "",
            isAnonymous: true,
            createdAt: "5分钟前",
            title: "北区食堂二楼新品测评，有人去试了吗？",
            summary: "听说新增了轻食窗口，想知道性价比和排队情况，准备明天去看看。",
            tags: ["校园生活", "食堂"],
            likeCount: 12,
            commentCount: 7
        ),
        CommunityPost(
            id: "post_latest_003",
            authorName: "图书馆志愿者",
            authorAvatarURL: "https://example.com/avatar/library.png",
            isAnonymous: false,
            createdAt: "12分钟前",
            title: "图书馆 3 楼自习区插座维护完成",
            summary: "之前反馈的插座接触问题已处理，今晚起可正常使用，欢迎继续反馈。",
            tags: ["公告", "图书馆"],
            likeCount: 24,
            commentCount: 5
        )
    ]

    static let communityCommentsByPostID: [String: [CommunityComment]] = [
        "post_hot_001": [
            CommunityComment(
                id: "comment_hot_001",
                authorName: "张同学",
                isAnonymous: false,
                createdAt: "3分钟前",
                content: "上次参加过这个系列分享，内容很实在，适合刚开始做项目的同学。",
                likeCount: 12
            ),
            CommunityComment(
                id: "comment_hot_002",
                authorName: "匿名用户",
                isAnonymous: true,
                createdAt: "9分钟前",
                content: "想问下现场会不会讲到接口联调和简历包装？",
                likeCount: 7
            )
        ],
        "post_hot_002": [
            CommunityComment(
                id: "comment_hot_003",
                authorName: "王雨晨",
                isAnonymous: false,
                createdAt: "11分钟前",
                content: "先抓范式、事务、索引和 SQL 查询优化，期中基本绕不开这些。",
                likeCount: 15
            )
        ],
        "post_latest_001": [
            CommunityComment(
                id: "comment_latest_001",
                authorName: "陈佳怡",
                isAnonymous: false,
                createdAt: "刚刚",
                content: "请问是线下活动吗？需要提前报名吗？",
                likeCount: 3
            )
        ]
    ]

    static func communityTopic(topicID: String) -> CommunityTopic {
        switch topicID {
        case "技术交流":
            return CommunityTopic(id: topicID, title: "#技术交流", summary: "分享开发经验、项目实践与技术活动。")
        case "社团活动":
            return CommunityTopic(id: topicID, title: "#社团活动", summary: "聚合校内社团招新、活动预告与经验交流。")
        case "学习互助":
            return CommunityTopic(id: topicID, title: "#学习互助", summary: "课程答疑、复习资料共享与组队学习。")
        case "课程讨论":
            return CommunityTopic(id: topicID, title: "#课程讨论", summary: "围绕课程内容、作业与考试安排交流。")
        case "校园活动":
            return CommunityTopic(id: topicID, title: "#校园活动", summary: "校园赛事、讲座和线下活动的集中入口。")
        case "志愿服务":
            return CommunityTopic(id: topicID, title: "#志愿服务", summary: "志愿者招募、服务心得和第二课堂资讯。")
        case "留学交流":
            return CommunityTopic(id: topicID, title: "#留学交流", summary: "交换申请、语言考试与海外学习经验。")
        case "讲座":
            return CommunityTopic(id: topicID, title: "#讲座", summary: "学术讲座、职业分享和专题活动汇总。")
        case "校园生活":
            return CommunityTopic(id: topicID, title: "#校园生活", summary: "食堂、宿舍、交通与日常生活信息分享。")
        case "食堂":
            return CommunityTopic(id: topicID, title: "#食堂", summary: "食堂窗口测评、菜单推荐和营业调整。")
        case "公告":
            return CommunityTopic(id: topicID, title: "#公告", summary: "校内设施维护、时间变更与官方提醒。")
        case "图书馆":
            return CommunityTopic(id: topicID, title: "#图书馆", summary: "馆藏检索、借阅经验和自习空间动态。")
        default:
            return CommunityTopic(id: topicID, title: "#\(topicID)", summary: "校园社区话题讨论。")
        }
    }

    static func communityPostContent(postID: String) -> String {
        switch postID {
        case "post_hot_001":
            return "这次分享会会从 SwiftUI 页面组织、项目目录结构、接口层封装三个方面展开，也会结合真实校园产品的迭代经验，聊一聊学生项目如何做出完成度。活动后半段会留出时间做现场答疑，欢迎带着自己的代码和问题来。"
        case "post_hot_002":
            return "最近数据库复习越看越乱，特别是事务隔离级别和关系代数部分，总觉得抓不住重点。想问问大家如果只有一周时间，应该先看教材、PPT 还是历年题？如果有整理好的笔记或者刷题路径，也想借鉴一下。"
        case "post_hot_003":
            return "今年校园马拉松计划扩大路线范围，志愿者需要协助起终点秩序维护、赛道补给和完赛引导。报名后会统一培训，服务时长可计入志愿学分。"
        case "post_latest_001":
            return "今晚英语角会邀请两位刚完成交换申请的学长学姐，重点分享语言成绩准备、文书时间线和院校选择逻辑。欢迎准备四六级后继续冲刺雅思托福的同学来听。"
        case "post_latest_002":
            return "最近北区食堂新开的轻食窗口很火，想看看大家吃过之后的真实评价。尤其想知道鸡胸肉套餐的分量和排队速度，适不适合赶课间隙去买。"
        case "post_latest_003":
            return "前几天很多同学反馈 3 楼插座接触不良，现在馆内维护已经完成。如果后续还有新问题，可以继续在本帖留言，方便集中反馈给图书馆老师。"
        default:
            return "这是一条来自校园社区的帖子详情内容，用于展示评论、标签和互动能力。"
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
        formatter.locale = Locale(identifier: "zh_CN")
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

    static let libraryBooks: [LibraryBook] = [
        LibraryBook(id: "book_001", title: "SwiftUI 实战指南", author: "陈智勇", availableCount: 3, location: "总馆 3F 技术区"),
        LibraryBook(id: "book_002", title: "算法图解", author: "Aditya Bhargava", availableCount: 1, location: "总馆 2F 计算机区"),
        LibraryBook(id: "book_003", title: "数据库系统概论", author: "王珊", availableCount: 0, location: "北馆 4F 教材区"),
        LibraryBook(id: "book_004", title: "计算机网络：自顶向下", author: "Kurose", availableCount: 2, location: "总馆 2F 计算机区")
    ]

    static func libraryBookDetail(bookID: String) -> LibraryBookDetail {
        if bookID == "book_002" {
            return LibraryBookDetail(
                id: "book_002",
                title: "算法图解",
                author: "Aditya Bhargava",
                publisher: "人民邮电出版社",
                isbn: "9787115447637",
                summary: "用图解方式讲解常见算法思想，适合算法入门与复习。",
                availableCount: 1,
                location: "总馆 2F 计算机区"
            )
        }

        if bookID == "book_003" {
            return LibraryBookDetail(
                id: "book_003",
                title: "数据库系统概论",
                author: "王珊",
                publisher: "高等教育出版社",
                isbn: "9787040587446",
                summary: "数据库课程核心教材，覆盖关系模型、SQL、事务与恢复等知识点。",
                availableCount: 0,
                location: "北馆 4F 教材区"
            )
        }

        if bookID == "book_004" {
            return LibraryBookDetail(
                id: "book_004",
                title: "计算机网络：自顶向下",
                author: "Kurose",
                publisher: "机械工业出版社",
                isbn: "9787111716485",
                summary: "以应用层到物理层的方式讲解网络基础，是网络课程常用参考书。",
                availableCount: 2,
                location: "总馆 2F 计算机区"
            )
        }

        return LibraryBookDetail(
            id: "book_001",
            title: "SwiftUI 实战指南",
            author: "陈智勇",
            publisher: "电子工业出版社",
            isbn: "9787121422338",
            summary: "围绕真实项目讲解 SwiftUI 组件、状态管理、网络交互与架构设计。",
            availableCount: 3,
            location: "总馆 3F 技术区"
        )
    }

    static func borrowRecords(renewedRecordIDs: Set<String>) -> [BorrowRecord] {
        [
            BorrowRecord(
                id: "borrow_001",
                bookTitle: "数据库系统概论",
                borrowDate: "2026-02-20",
                dueDate: renewedRecordIDs.contains("borrow_001") ? "2026-04-06" : "2026-03-23",
                status: renewedRecordIDs.contains("borrow_001") ? "已续借一次" : "借阅中",
                renewable: !renewedRecordIDs.contains("borrow_001"),
                sn: "borrow_001",
                code: "code_001"
            ),
            BorrowRecord(
                id: "borrow_002",
                bookTitle: "计算机网络：自顶向下",
                borrowDate: "2026-02-28",
                dueDate: "2026-03-31",
                status: "借阅中",
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
