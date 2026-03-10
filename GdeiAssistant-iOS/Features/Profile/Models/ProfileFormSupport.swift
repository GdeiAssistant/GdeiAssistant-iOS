import Foundation

struct ProfileLocationCity: Codable, Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }
}

struct ProfileLocationState: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let cities: [ProfileLocationCity]

    var id: String { code }
}

struct ProfileLocationRegion: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let states: [ProfileLocationState]

    var id: String { code }
}

struct ProfileLocationSelection: Hashable {
    let displayName: String
    let regionCode: String
    let stateCode: String
    let cityCode: String
}

enum ProfileFormSupport {
    // 与 frontend/src/views/Profile.vue 中的 facultyData 保持一致。
    static let facultyOptions: [String] = [
        "未选择",
        "教育学院",
        "政法系",
        "中文系",
        "数学系",
        "外语系",
        "物理与信息工程系",
        "化学系",
        "生物与食品工程学院",
        "体育学院",
        "美术学院",
        "计算机科学系",
        "音乐系",
        "教师研修学院",
        "成人教育学院",
        "网络教育学院",
        "马克思主义学院"
    ]

    static let majorOptionsByFaculty: [String: [String]] = [
        "未选择": ["未选择"],
        "教育学院": ["未选择", "教育学", "学前教育", "小学教育", "特殊教育"],
        "政法系": ["未选择", "法学", "思想政治教育", "社会工作"],
        "中文系": ["未选择", "汉语言文学", "历史学", "秘书学"],
        "数学系": ["未选择", "数学与应用数学", "信息与计算科学", "统计学"],
        "外语系": ["未选择", "英语", "商务英语", "日语", "翻译"],
        "物理与信息工程系": ["未选择", "物理学", "电子信息工程", "通信工程"],
        "化学系": ["未选择", "化学", "应用化学", "材料化学"],
        "生物与食品工程学院": ["未选择", "生物科学", "生物技术", "食品科学与工程"],
        "体育学院": ["未选择", "体育教育", "社会体育指导与管理"],
        "美术学院": ["未选择", "美术学", "视觉传达设计", "环境设计"],
        "计算机科学系": ["未选择", "软件工程", "网络工程", "计算机科学与技术", "物联网工程"],
        "音乐系": ["未选择", "音乐学", "音乐表演", "舞蹈学"],
        "教师研修学院": ["未选择", "教育学", "教育技术学"],
        "成人教育学院": ["未选择", "汉语言文学", "学前教育", "行政管理"],
        "网络教育学院": ["未选择", "计算机科学与技术", "工商管理", "会计学"],
        "马克思主义学院": ["未选择", "思想政治教育", "马克思主义理论"]
    ]

    static var enrollmentOptions: [String] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (2014...currentYear).map(String.init)
    }

    static func majorOptions(for faculty: String) -> [String] {
        majorOptionsByFaculty[faculty] ?? ["未选择"]
    }

    static func canSelectMajor(for faculty: String) -> Bool {
        let normalized = faculty.trimmingCharacters(in: .whitespacesAndNewlines)
        return !normalized.isEmpty && normalized != "未选择"
    }

    static func makeLocationDisplay(region: String, state: String, city: String) -> String {
        [region, state, city]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, item in
                if result.last != item {
                    result.append(item)
                }
            }
            .joined(separator: " ")
    }
}
