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

struct ProfileDictionaryOption: Codable, Hashable, Identifiable {
    let code: Int
    let label: String

    var id: Int { code }
}

struct ProfileFacultyOption: Codable, Hashable, Identifiable {
    let code: Int
    let label: String
    let majors: [String]

    var id: Int { code }
}

struct ProfileOptions: Codable, Hashable {
    let faculties: [ProfileFacultyOption]
    let marketplaceItemTypes: [ProfileDictionaryOption]
    let lostFoundItemTypes: [ProfileDictionaryOption]
    let lostFoundModes: [ProfileDictionaryOption]

    var facultyOptions: [String] {
        faculties.map(\.label)
    }

    func majorOptions(for faculty: String) -> [String] {
        let normalizedFaculty = normalizeOptionLookup(faculty)
        return faculties.first(where: { normalizeOptionLookup($0.label) == normalizedFaculty })?.majors ?? [ProfileFormSupport.unselectedOption]
    }

    func canSelectMajor(for faculty: String) -> Bool {
        let normalizedFaculty = faculty.trimmingCharacters(in: .whitespacesAndNewlines)
        return !normalizedFaculty.isEmpty && normalizedFaculty != ProfileFormSupport.unselectedOption
    }

    func facultyCode(for college: String) -> Int? {
        let normalizedCollege = normalizeOptionLookup(college)
        return faculties.first(where: { normalizeOptionLookup($0.label) == normalizedCollege })?.code
    }
}

enum ProfileFormSupport {
    static let unselectedOption = "未选择"

    static let defaultOptions = ProfileOptions(
        faculties: [
            ProfileFacultyOption(code: 0, label: unselectedOption, majors: [unselectedOption]),
            ProfileFacultyOption(code: 1, label: "教育学院", majors: [unselectedOption, "教育学", "学前教育", "小学教育", "特殊教育"]),
            ProfileFacultyOption(code: 2, label: "政法系", majors: [unselectedOption, "法学", "思想政治教育", "社会工作"]),
            ProfileFacultyOption(code: 3, label: "中文系", majors: [unselectedOption, "汉语言文学", "历史学", "秘书学"]),
            ProfileFacultyOption(code: 4, label: "数学系", majors: [unselectedOption, "数学与应用数学", "信息与计算科学", "统计学"]),
            ProfileFacultyOption(code: 5, label: "外语系", majors: [unselectedOption, "英语", "商务英语", "日语", "翻译"]),
            ProfileFacultyOption(code: 6, label: "物理与信息工程系", majors: [unselectedOption, "物理学", "电子信息工程", "通信工程"]),
            ProfileFacultyOption(code: 7, label: "化学系", majors: [unselectedOption, "化学", "应用化学", "材料化学"]),
            ProfileFacultyOption(code: 8, label: "生物与食品工程学院", majors: [unselectedOption, "生物科学", "生物技术", "食品科学与工程"]),
            ProfileFacultyOption(code: 9, label: "体育学院", majors: [unselectedOption, "体育教育", "社会体育指导与管理"]),
            ProfileFacultyOption(code: 10, label: "美术学院", majors: [unselectedOption, "美术学", "视觉传达设计", "环境设计"]),
            ProfileFacultyOption(code: 11, label: "计算机科学系", majors: [unselectedOption, "软件工程", "网络工程", "计算机科学与技术", "物联网工程"]),
            ProfileFacultyOption(code: 12, label: "音乐系", majors: [unselectedOption, "音乐学", "音乐表演", "舞蹈学"]),
            ProfileFacultyOption(code: 13, label: "教师研修学院", majors: [unselectedOption, "教育学", "教育技术学"]),
            ProfileFacultyOption(code: 14, label: "成人教育学院", majors: [unselectedOption, "汉语言文学", "学前教育", "行政管理"]),
            ProfileFacultyOption(code: 15, label: "网络教育学院", majors: [unselectedOption, "计算机科学与技术", "工商管理", "会计学"]),
            ProfileFacultyOption(code: 16, label: "马克思主义学院", majors: [unselectedOption, "思想政治教育", "马克思主义理论"])
        ],
        marketplaceItemTypes: [
            ProfileDictionaryOption(code: 0, label: "校园代步"),
            ProfileDictionaryOption(code: 1, label: "手机"),
            ProfileDictionaryOption(code: 2, label: "电脑"),
            ProfileDictionaryOption(code: 3, label: "数码配件"),
            ProfileDictionaryOption(code: 4, label: "数码"),
            ProfileDictionaryOption(code: 5, label: "电器"),
            ProfileDictionaryOption(code: 6, label: "运动健身"),
            ProfileDictionaryOption(code: 7, label: "衣物伞帽"),
            ProfileDictionaryOption(code: 8, label: "图书教材"),
            ProfileDictionaryOption(code: 9, label: "租赁"),
            ProfileDictionaryOption(code: 10, label: "生活娱乐"),
            ProfileDictionaryOption(code: 11, label: "其他")
        ],
        lostFoundItemTypes: [
            ProfileDictionaryOption(code: 0, label: "手机"),
            ProfileDictionaryOption(code: 1, label: "校园卡"),
            ProfileDictionaryOption(code: 2, label: "身份证"),
            ProfileDictionaryOption(code: 3, label: "银行卡"),
            ProfileDictionaryOption(code: 4, label: "书"),
            ProfileDictionaryOption(code: 5, label: "钥匙"),
            ProfileDictionaryOption(code: 6, label: "包包"),
            ProfileDictionaryOption(code: 7, label: "衣帽"),
            ProfileDictionaryOption(code: 8, label: "校园代步"),
            ProfileDictionaryOption(code: 9, label: "运动健身"),
            ProfileDictionaryOption(code: 10, label: "数码配件"),
            ProfileDictionaryOption(code: 11, label: "其他")
        ],
        lostFoundModes: [
            ProfileDictionaryOption(code: 0, label: "寻物启事"),
            ProfileDictionaryOption(code: 1, label: "失物招领")
        ]
    )

    static var enrollmentOptions: [String] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (2014...currentYear).map(String.init)
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

private func normalizeOptionLookup(_ value: String) -> String {
    value
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "\u{3000}", with: "")
}
