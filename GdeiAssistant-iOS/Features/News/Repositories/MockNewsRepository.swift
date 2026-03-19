import Foundation

@MainActor
final class MockNewsRepository: NewsRepository {
    private let items = [
        NewsItem(id: "news_1", type: 1, title: "学校高质量发展大会暨 2026 年工作会议召开", publishDate: "2026-03-03", content: "学校召开高质量发展大会，系统总结上一阶段重点工作，并部署年度改革发展任务。", sourceURL: "https://www.gdei.edu.cn/1324/1001.htm"),
        NewsItem(id: "news_2", type: 2, title: "管理学院召开教职工思想教育会议", publishDate: "2026-03-19", content: "管理学院围绕师德师风建设与年度重点工作召开专题会议。", sourceURL: "https://www.gdei.edu.cn/1325/2001.htm"),
        NewsItem(id: "news_3", type: 3, title: "关于网站群管理平台升级切换的通知", publishDate: "2026-01-22", content: "学校主页及部分二级网站将在指定时间窗口内短暂停止访问。", sourceURL: "https://www.gdei.edu.cn/1376/3001.htm"),
        NewsItem(id: "news_4", type: 4, title: "美术学院举办高层次科研项目申报学术讲座", publishDate: "2026-03-09", content: "讲座围绕高层次科研项目选题、申报书撰写和团队协作展开。", sourceURL: "https://www.gdei.edu.cn/3981/4001.htm"),
        NewsItem(id: "news_5", type: 1, title: "学校启动春季学期教学巡查工作", publishDate: "2026-02-26", content: "学校启动春季学期教学巡查，持续关注课堂秩序与教学保障。", sourceURL: "https://www.gdei.edu.cn/1324/1002.htm"),
        NewsItem(id: "news_6", type: 4, title: "教育学院开展人工智能赋能教学专题分享", publishDate: "2026-02-24", content: "专题分享聚焦生成式人工智能在教学设计与学习评价中的应用。", sourceURL: "https://www.gdei.edu.cn/3981/4002.htm")
    ]

    func fetchNews(start: Int, size: Int) async throws -> [NewsItem] {
        try await Task.sleep(nanoseconds: 120_000_000)
        let safeStart = max(start, 0)
        let safeSize = max(size, 1)
        guard safeStart < items.count else { return [] }
        return Array(items.dropFirst(safeStart).prefix(safeSize))
    }

    func fetchNewsDetail(id: String) async throws -> NewsItem {
        try await Task.sleep(nanoseconds: 80_000_000)
        if let item = items.first(where: { $0.id == id }) {
            return item
        }
        throw NetworkError.server(code: 404, message: "新闻通知不存在")
    }
}
