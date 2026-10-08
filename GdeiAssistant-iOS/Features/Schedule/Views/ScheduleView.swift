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
        let nonEmptyDays = schedule.days.filter { !$0.courses.isEmpty }

        return List {
            Section {
                HStack {
                    Button {
                        Task { await viewModel.previousWeek() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(DSColor.primary)
                    .accessibilityLabel(localizedString("schedule.title"))

                    Spacer()

                    VStack(spacing: 2) {
                        Text(schedule.termName)
                            .font(.footnote)
                            .foregroundStyle(DSColor.subtitle)
                        Text(String(format: localizedString("schedule.weekLabel"), schedule.weekIndex))
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(DSColor.title)
                    }
                    .multilineTextAlignment(.center)

                    Spacer()

                    Button {
                        Task { await viewModel.nextWeek() }
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(DSColor.primary)
                }
                .buttonStyle(.plain)
            }

            Section {
                if viewModel.todayCourses.isEmpty {
                    Text(LocalizedStringKey("schedule.noCourses"))
                        .foregroundStyle(DSColor.subtitle)
                } else {
                    ForEach(viewModel.todayCourses) { course in
                        Button {
                            selectedCourse = course
                        } label: {
                            courseSummaryRow(course)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text(LocalizedStringKey("schedule.todayCourses"))
            }

            Section {
                ScheduleGridView(
                    schedule: schedule,
                    backgroundImage: backgroundImage,
                    onSelectCourse: { selectedCourse = $0 }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            } header: {
                Text(LocalizedStringKey("schedule.weeklyGrid"))
            }

            if nonEmptyDays.isEmpty {
                Section {
                    Text(LocalizedStringKey("schedule.noCourses"))
                        .foregroundStyle(DSColor.subtitle)
                } header: {
                    Text(LocalizedStringKey("schedule.fullList"))
                }
            } else {
                ForEach(nonEmptyDays) { day in
                    Section {
                        ForEach(day.courses) { course in
                            Button {
                                selectedCourse = course
                            } label: {
                                courseSummaryRow(course)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        HStack {
                            Text(day.dayTitle)
                            if !day.dateText.isEmpty {
                                Text(day.dateText)
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
        .refreshable {
            await viewModel.loadSchedule()
        }
    }

    private func courseSummaryRow(_ course: CourseItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(course.courseName)
                .font(.body)
                .foregroundStyle(DSColor.title)
            Text(String(format: localizedString("schedule.sectionLocation"), course.startSection, course.endSection, course.location))
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(DSColor.subtitle)
            Text(course.teacherName)
                .font(.footnote)
                .foregroundStyle(DSColor.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
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

    @ScaledMetric(relativeTo: .caption2) private var cellHeight: CGFloat = 38

    private let timeColumnWidth: CGFloat = 26
    private let headerHeight: CGFloat = 42
    private let blockInset: CGFloat = 3
    private let sectionCount = 10
    private let gridCornerRadius: CGFloat = DSRadius.control

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
                                    .font(.caption2)
                                    .monospacedDigit()
                                    .foregroundStyle(DSColor.subtitle)
                            }
                        }
                        .frame(width: dayColumnWidth, height: headerHeight)
                        .background(isToday(day.dayOfWeek) ? DSColor.primarySoft : Color.clear)
                        .accessibilityElement(children: .combine)
                    }
                }

                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(1...sectionCount, id: \.self) { section in
                            Text("\(section)")
                                .font(.caption2.weight(.medium))
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
                                    DSColor.surface.opacity(0.2)
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
                            .strokeBorder(DSColor.border, lineWidth: 1)
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
                            Rectangle().stroke(DSColor.divider, lineWidth: 0.5)
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
                ? DSColor.primarySoft.opacity(0.7)
                : DSColor.surface.opacity(0.36)
        }

        return isToday(dayOfWeek)
            ? DSColor.primarySoft.opacity(0.6)
            : DSColor.surface
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
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DSColor.title)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Text(course.location)
                    .font(.caption2)
                    .foregroundStyle(DSColor.subtitle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(.leading, 6)
            .padding(.trailing, 3)
            .padding(.vertical, 5)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(DSColor.primarySoft)
            .overlay(alignment: .leading) {
                DSColor.primary.frame(width: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.compact, style: .continuous))
        }
        .buttonStyle(DSPressableButtonStyle())
    }

    private var height: CGFloat {
        CGFloat(max(course.endSection - course.startSection + 1, 1)) * cellHeight - 8
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
            .dsListBackground()
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
