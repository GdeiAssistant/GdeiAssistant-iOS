import Foundation

@MainActor
final class MockReadingRepository: ReadingRepository {
    private let items = [
        ReadingItem(id: "reading_1", title: "春招简历如何写出项目亮点", summary: "结合校园项目和实习经历，整理出适合开发岗的简历表达方式。", link: "https://example.com/reading/resume", createdAt: "2026-03-08"),
        ReadingItem(id: "reading_2", title: "图书馆高效自习方法整理", summary: "从番茄钟、资料归档到错题复盘，建立稳定的学习节奏。", link: "https://example.com/reading/library", createdAt: "2026-03-06"),
        ReadingItem(id: "reading_3", title: "四六级冲刺阶段的听力复习建议", summary: "最后两周如何提高正确率，并避免时间分配失衡。", link: "https://example.com/reading/cet", createdAt: "2026-03-04"),
        ReadingItem(id: "reading_4", title: "选修课如何快速建立知识框架", summary: "用最少的时间梳理课程结构，避免期末临时抱佛脚。", link: "https://example.com/reading/elective", createdAt: "2026-03-02"),
        ReadingItem(id: "reading_5", title: "社团招新面试常见问题整理", summary: "把常见提问拆成表达思路，帮助第一次参加面试的同学准备发言。", link: "https://example.com/reading/club", createdAt: "2026-02-28")
    ]

    func fetchReadings(start: Int, size: Int) async throws -> [ReadingItem] {
        try await Task.sleep(nanoseconds: 120_000_000)
        let safeStart = max(start, 0)
        let safeSize = max(size, 1)
        guard safeStart < items.count else { return [] }
        return Array(items.dropFirst(safeStart).prefix(safeSize))
    }
}
