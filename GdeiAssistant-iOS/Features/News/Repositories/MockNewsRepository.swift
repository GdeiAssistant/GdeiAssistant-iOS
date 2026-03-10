import Foundation

@MainActor
final class MockNewsRepository: NewsRepository {
    func fetchNews(category: NewsCategory, start: Int, size: Int) async throws -> [NewsItem] {
        try await Task.sleep(nanoseconds: 120_000_000)
        let items = [
            NewsItem(id: "news_1", category: .teaching, title: "下周《移动应用开发》实验课教室调整", publishDate: "2026-03-08", content: "实验课将调整到教学楼 B402，请同学们提前查看课表通知。"),
            NewsItem(id: "news_2", category: .exam, title: "大学英语六级模拟考试安排发布", publishDate: "2026-03-07", content: "模拟考试将于本周六上午 9 点进行，地点见准考证。"),
            NewsItem(id: "news_3", category: .admin, title: "白云校区图书馆临时闭馆维护", publishDate: "2026-03-06", content: "因设备维护，图书馆将于周日 8:00-12:00 暂停开放。"),
            NewsItem(id: "news_4", category: .campus, title: "春季校园招聘双选会报名开启", publishDate: "2026-03-05", content: "双选会将于体育馆举行，报名截止至周四中午。")
        ]
        return Array(items.filter { $0.category == category }.dropFirst(start).prefix(size))
    }
}
