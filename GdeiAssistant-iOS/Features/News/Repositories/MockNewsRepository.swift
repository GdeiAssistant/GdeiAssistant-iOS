import Foundation

@MainActor
final class MockNewsRepository: NewsRepository {
    private let items = [
        NewsItem(id: "news_1", title: "下周《移动应用开发》实验课教室调整", publishDate: "2026-03-08", content: "实验课将调整到教学楼 B402，请同学们提前查看课表通知。"),
        NewsItem(id: "news_2", title: "大学英语六级模拟考试安排发布", publishDate: "2026-03-07", content: "模拟考试将于本周六上午 9 点进行，地点见准考证。"),
        NewsItem(id: "news_3", title: "白云校区图书馆临时闭馆维护", publishDate: "2026-03-06", content: "因设备维护，图书馆将于周日 8:00-12:00 暂停开放。"),
        NewsItem(id: "news_4", title: "春季校园招聘双选会报名开启", publishDate: "2026-03-05", content: "双选会将于体育馆举行，报名截止至周四中午。"),
        NewsItem(id: "news_5", title: "体育馆临时借用安排更新", publishDate: "2026-03-04", content: "本周末体育馆将优先保障校级活动，部分场地借用时间已调整。"),
        NewsItem(id: "news_6", title: "宿舍区热水系统例行检修", publishDate: "2026-03-03", content: "北区宿舍热水系统将于明晚分时段检修，请提前安排洗漱时间。")
    ]

    func fetchNews(start: Int, size: Int) async throws -> [NewsItem] {
        try await Task.sleep(nanoseconds: 120_000_000)
        let safeStart = max(start, 0)
        let safeSize = max(size, 1)
        guard safeStart < items.count else { return [] }
        return Array(items.dropFirst(safeStart).prefix(safeSize))
    }
}
