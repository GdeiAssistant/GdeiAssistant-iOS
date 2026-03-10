import SwiftUI
import PhotosUI
import UIKit

struct ScheduleView: View {
    @StateObject private var viewModel: ScheduleViewModel
    @State private var selectedBackgroundItem: PhotosPickerItem?
    @State private var backgroundImage: UIImage?
    @State private var selectedCourse: CourseItem?

    init(viewModel: ScheduleViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.schedule == nil {
                DSLoadingView(text: "正在加载课表...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.schedule == nil {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.loadSchedule() }
                }
            } else if let schedule = viewModel.schedule {
                content(schedule)
            } else {
                DSEmptyStateView(icon: "calendar", title: "暂无课表数据", message: "请稍后重试")
            }
        }
        .navigationTitle("我的课程表")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    PhotosPicker(selection: $selectedBackgroundItem, matching: .images) {
                        Label("选择背景图", systemImage: "photo")
                    }

                    if backgroundImage != nil {
                        Button("清除背景图", role: .destructive) {
                            clearBackground()
                        }
                    }
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
            backgroundImage = ScheduleBackgroundStore.loadImage()
        }
        .onChange(of: selectedBackgroundItem) { _, newValue in
            Task { await importBackground(from: newValue) }
        }
        .sheet(item: $selectedCourse) { course in
            ScheduleCourseDetailView(course: course)
        }
    }

    private func content(_ schedule: WeeklySchedule) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                DSCard {
                    HStack {
                        Button {
                            Task { await viewModel.previousWeek() }
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(DSColor.primary)
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Text(schedule.termName)
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                            Text("第 \(schedule.weekIndex) 周")
                                .font(.headline)
                                .foregroundStyle(DSColor.title)
                        }

                        Spacer()

                        Button {
                            Task { await viewModel.nextWeek() }
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(DSColor.primary)
                        }
                    }
                }

                DSCard {
                    Text("今日课程")
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    if viewModel.todayCourses.isEmpty {
                        Text("今天没有课程安排")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                    } else {
                        ForEach(viewModel.todayCourses) { course in
                            courseSummaryRow(course)
                        }
                    }
                }

                DSCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("周课表")
                            .font(.headline)
                            .foregroundStyle(DSColor.title)

                        ScheduleGridView(
                            schedule: schedule,
                            backgroundImage: backgroundImage,
                            onSelectCourse: { selectedCourse = $0 }
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .refreshable {
            await viewModel.loadSchedule()
        }
    }

    private func courseSummaryRow(_ course: CourseItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(course.courseName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DSColor.title)

            Text("第 \(course.startSection)-\(course.endSection) 节 · \(course.location)")
                .font(.caption)
                .foregroundStyle(DSColor.subtitle)

            Text(course.teacherName)
                .font(.caption)
                .foregroundStyle(DSColor.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func importBackground(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let storedImage = ScheduleBackgroundStore.save(image: image) else {
                return
            }
            backgroundImage = storedImage
        } catch {
            // 本地背景图读取失败时保持现状，不影响课表主流程
        }
    }

    private func clearBackground() {
        ScheduleBackgroundStore.clear()
        backgroundImage = nil
    }
}

private struct ScheduleGridView: View {
    let schedule: WeeklySchedule
    let backgroundImage: UIImage?
    let onSelectCourse: (CourseItem) -> Void

    private let timeColumnWidth: CGFloat = 26
    private let cellHeight: CGFloat = 38
    private let headerHeight: CGFloat = 42
    private let blockInset: CGFloat = 3
    private let sectionCount = 10

    var body: some View {
        GeometryReader { proxy in
            let dayCount = CGFloat(max(schedule.days.count, 1))
            let availableWidth = max(proxy.size.width - timeColumnWidth, 0)
            let dayColumnWidth = availableWidth / dayCount
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: timeColumnWidth, height: headerHeight)

                    ForEach(schedule.days) { day in
                        VStack(spacing: 2) {
                            Text(day.dayTitle)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(isToday(day.dayOfWeek) ? DSColor.primary : DSColor.title)
                            if !day.dateText.isEmpty {
                                Text(day.dateText)
                                    .font(.system(size: 9))
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        }
                        .frame(width: dayColumnWidth, height: headerHeight)
                        .background(isToday(day.dayOfWeek) ? DSColor.primary.opacity(0.08) : Color.clear)
                    }
                }

                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(1...sectionCount, id: \.self) { section in
                            Text("\(section)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(DSColor.subtitle)
                                .frame(width: timeColumnWidth, height: cellHeight)
                                .overlay(alignment: .bottom) {
                                    Divider()
                                }
                        }
                    }

                    ZStack(alignment: .topLeading) {
                        if let backgroundImage {
                            Image(uiImage: backgroundImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: dayColumnWidth * CGFloat(schedule.days.count), height: totalHeight)
                                .clipped()
                                .opacity(0.14)
                        }

                        HStack(spacing: 0) {
                            ForEach(schedule.days) { day in
                                dayColumn(day, dayColumnWidth: dayColumnWidth)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .frame(height: totalHeight + headerHeight)
    }

    private var totalHeight: CGFloat {
        CGFloat(sectionCount) * cellHeight
    }

    private func dayColumn(_ day: CourseDaySection, dayColumnWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(1...sectionCount, id: \.self) { _ in
                    Rectangle()
                        .fill(isToday(day.dayOfWeek) ? DSColor.primary.opacity(0.05) : Color(.tertiarySystemGroupedBackground).opacity(0.9))
                        .frame(width: dayColumnWidth, height: cellHeight)
                        .overlay(
                            Rectangle().stroke(Color(.separator).opacity(0.35), lineWidth: 0.5)
                        )
                }
            }

            ForEach(day.courses) { course in
                ScheduleCourseBlock(
                    course: course,
                    width: max(dayColumnWidth - (blockInset * 2), 0),
                    cellHeight: cellHeight,
                    onTap: { onSelectCourse(course) }
                )
                    .offset(
                        x: blockInset,
                        y: CGFloat(max(course.startSection - 1, 0)) * cellHeight + blockInset
                    )
            }
        }
        .frame(width: dayColumnWidth, height: totalHeight)
    }

    private func isToday(_ dayOfWeek: Int) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let normalizedWeekday = ((weekday + 5) % 7) + 1
        return normalizedWeekday == dayOfWeek
    }
}

private struct ScheduleCourseBlock: View {
    let course: CourseItem
    let width: CGFloat
    let cellHeight: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(course.courseName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Text(course.location)
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 5)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(blockColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: blockColor.opacity(0.18), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var height: CGFloat {
        CGFloat(max(course.endSection - course.startSection + 1, 1)) * cellHeight - 8
    }

    private var blockColor: Color {
        let palette: [Color] = [
            DSColor.primary,
            DSColor.secondary,
            DSColor.warning,
            Color(red: 0.19, green: 0.58, blue: 0.82),
            Color(red: 0.27, green: 0.65, blue: 0.54),
            Color(red: 0.80, green: 0.47, blue: 0.24)
        ]
        let index = abs(course.courseName.hashValue) % palette.count
        return palette[index]
    }
}

private struct ScheduleCourseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let course: CourseItem

    var body: some View {
        NavigationStack {
            List {
                infoRow("课程", course.courseName)
                infoRow("教师", course.teacherName)
                infoRow("地点", course.location)
                infoRow("节次", "第 \(course.startSection)-\(course.endSection) 节")
                infoRow("星期", weekdayText(course.dayOfWeek))
                infoRow("周次", course.weekIndices.isEmpty ? "全周" : course.weekIndices.map(String.init).joined(separator: "、"))
            }
            .navigationTitle("课程详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(DSColor.subtitle)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(DSColor.title)
        }
    }

    private func weekdayText(_ dayOfWeek: Int) -> String {
        switch dayOfWeek {
        case 1: return "星期一"
        case 2: return "星期二"
        case 3: return "星期三"
        case 4: return "星期四"
        case 5: return "星期五"
        case 6: return "星期六"
        case 7: return "星期日"
        default: return "未知"
        }
    }
}

private enum ScheduleBackgroundStore {
    private static let fileName = "schedule_background.jpg"
    private static let directoryName = "Schedule"

    static func loadImage() -> UIImage? {
        guard let url = fileURL(),
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    @discardableResult
    static func save(image: UIImage) -> UIImage? {
        guard let url = fileURL() else { return nil }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let normalizedImage = image.normalizedImage()
            guard let data = normalizedImage.jpegData(compressionQuality: 0.85) else {
                return nil
            }
            try data.write(to: url, options: .atomic)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    static func clear() {
        guard let url = fileURL() else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private static func fileURL() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(fileName)
    }
}

private extension UIImage {
    func normalizedImage() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    NavigationStack {
        ScheduleView(viewModel: ScheduleViewModel(repository: MockScheduleRepository()))
    }
}
