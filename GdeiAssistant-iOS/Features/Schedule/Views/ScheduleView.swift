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
                DSLoadingView(text: localizedString("schedule.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.schedule == nil {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.loadSchedule() }
                }
            } else if let schedule = viewModel.schedule {
                content(schedule)
            } else {
                DSEmptyStateView(icon: "calendar", title: localizedString("schedule.emptyTitle"), message: localizedString("schedule.emptyMessage"))
            }
        }
        .navigationTitle(localizedString("schedule.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    PhotosPicker(selection: $selectedBackgroundItem, matching: .images) {
                        Label(backgroundImage == nil ? localizedString("schedule.selectBackground") : localizedString("schedule.changeBackground"), systemImage: "photo")
                    }

                    if backgroundImage != nil {
                        Button(localizedString("schedule.clearBackground"), role: .destructive) {
                            clearBackground()
                        }
                    }
                } label: {
                    Image(systemName: backgroundImage == nil ? "photo.on.rectangle.angled" : "photo.on.rectangle.angled.fill")
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
                            Text(String(format: localizedString("schedule.weekLabel"), schedule.weekIndex))
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
                    Text(LocalizedStringKey("schedule.todayCourses"))
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    if viewModel.todayCourses.isEmpty {
                        Text(LocalizedStringKey("schedule.noCourses"))
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
                        Text(LocalizedStringKey("schedule.weeklyGrid"))
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

            Text(String(format: localizedString("schedule.sectionLocation"), course.startSection, course.endSection, course.location))
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
        defer { selectedBackgroundItem = nil }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let storedImage = ScheduleBackgroundStore.save(image: image) else {
                return
            }
            backgroundImage = storedImage
        } catch {
            // Keep current state when background image loading fails
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

    @ScaledMetric(relativeTo: .caption2) private var dateTextSize: CGFloat = 9
    @ScaledMetric(relativeTo: .caption2) private var sectionNumberSize: CGFloat = 10

    private let timeColumnWidth: CGFloat = 26
    private let cellHeight: CGFloat = 38
    private let headerHeight: CGFloat = 42
    private let blockInset: CGFloat = 3
    private let sectionCount = 10
    private let gridCornerRadius: CGFloat = 12

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
                                    .font(.system(size: dateTextSize))
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
                                .font(.system(size: sectionNumberSize, weight: .medium))
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
                                .overlay {
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.12),
                                            Color.white.opacity(0.24)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                                .opacity(0.52)
                        }

                        HStack(spacing: 0) {
                            ForEach(schedule.days) { day in
                                dayColumn(day, dayColumnWidth: dayColumnWidth)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: gridCornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: gridCornerRadius, style: .continuous)
                            .stroke(Color(.separator).opacity(0.2), lineWidth: 0.8)
                    }
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
                        .fill(backgroundFillColor(for: day.dayOfWeek))
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

    private func backgroundFillColor(for dayOfWeek: Int) -> Color {
        if backgroundImage != nil {
            return isToday(dayOfWeek)
                ? DSColor.primary.opacity(0.18)
                : Color.white.opacity(0.36)
        }

        return isToday(dayOfWeek)
            ? DSColor.primary.opacity(0.05)
            : Color(.tertiarySystemGroupedBackground).opacity(0.9)
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

    @ScaledMetric(relativeTo: .caption2) private var courseNameSize: CGFloat = 10
    @ScaledMetric(relativeTo: .caption2) private var locationSize: CGFloat = 8

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(course.courseName)
                    .font(.system(size: courseNameSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Text(course.location)
                    .font(.system(size: locationSize))
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
                infoRow(localizedString("schedule.course"), course.courseName)
                infoRow(localizedString("schedule.teacher"), course.teacherName)
                infoRow(localizedString("schedule.location"), course.location)
                infoRow(localizedString("schedule.section"), String(format: localizedString("schedule.sectionRange"), course.startSection, course.endSection))
                infoRow(localizedString("schedule.dayOfWeek"), weekdayText(course.dayOfWeek))
                infoRow(localizedString("schedule.weeks"), course.weekIndices.isEmpty ? localizedString("schedule.allWeeks") : course.weekIndices.map(String.init).joined(separator: "\u{3001}"))
            }
            .navigationTitle(localizedString("schedule.courseDetail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localizedString("schedule.close")) {
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
        case 1: return localizedString("schedule.weekday.mon")
        case 2: return localizedString("schedule.weekday.tue")
        case 3: return localizedString("schedule.weekday.wed")
        case 4: return localizedString("schedule.weekday.thu")
        case 5: return localizedString("schedule.weekday.fri")
        case 6: return localizedString("schedule.weekday.sat")
        case 7: return localizedString("schedule.weekday.sun")
        default: return localizedString("schedule.weekday.unknown")
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
            let preparedImage = image.preparedScheduleBackgroundImage()
            guard let data = preparedImage.jpegData(compressionQuality: 0.82) else {
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

    func preparedScheduleBackgroundImage(maxDimension: CGFloat = 1600) -> UIImage {
        let normalized = normalizedImage()
        let longestSide = max(normalized.size.width, normalized.size.height)
        guard longestSide > maxDimension else { return normalized }

        let scale = maxDimension / longestSide
        let scaledSize = CGSize(
            width: normalized.size.width * scale,
            height: normalized.size.height * scale
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true

        return UIGraphicsImageRenderer(size: scaledSize, format: format).image { _ in
            normalized.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
}

#Preview {
    NavigationStack {
        ScheduleView(viewModel: ScheduleViewModel(repository: MockScheduleRepository()))
    }
}
