import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var container: AppContainer
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            contentView
            .navigationTitle(localizedString("home.title"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadIfNeeded()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await viewModel.loadIfNeeded() }
                }
            }
        }
    }

    private var contentView: some View {
        List {
            Section {
                HomeTodayCoursesCard(
                    courses: viewModel.todayCourses,
                    isLoading: viewModel.isScheduleLoading || (viewModel.currentSchedule == nil && !viewModel.scheduleLoadFailed),
                    loadFailed: viewModel.scheduleLoadFailed
                )
            } header: {
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(viewModel.todayDate, format: Date.FormatStyle(
                        date: .abbreviated,
                        time: .omitted,
                        locale: locale,
                        calendar: HomeViewModel.campusCalendar,
                        timeZone: HomeViewModel.campusCalendar.timeZone
                    ))
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)

                    HStack {
                        Label(localizedString("schedule.todayCourses"), systemImage: "clock")
                            .font(.headline)
                        Spacer()
                        NavigationLink {
                            if let currentWeek = viewModel.currentSchedule?.weekIndex {
                                ScheduleView(viewModel: ScheduleViewModel(
                                    repository: container.scheduleRepository,
                                    initialWeekIndex: currentWeek
                                ))
                            } else {
                                ScheduleView(viewModel: container.makeScheduleViewModel())
                            }
                        } label: {
                            Text(LocalizedStringKey("schedule.title"))
                                .font(.subheadline)
                        }
                        .accessibilityIdentifier("home.todayCourses.schedule")
                    }
                    .foregroundStyle(DSColor.primary)
                }
            }

            if viewModel.dashboard == nil, let error = viewModel.errorMessage {
                Section {
                    DSErrorStateView(message: error) {
                        Task { await viewModel.loadDashboard() }
                    }
                }
            }

            ForEach(HomeEntryConfig.allSections) { section in
                if !section.entries.isEmpty {
                    Section {
                        ForEach(section.entries) { entry in
                            NavigationLink {
                                destinationView(for: entry.destination)
                            } label: {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.title)
                                            .font(.body)
                                            .foregroundStyle(DSColor.title)
                                        Text(entry.subtitle)
                                            .font(.footnote)
                                            .foregroundStyle(DSColor.subtitle)
                                            .lineLimit(2)
                                    }
                                } icon: {
                                    DSIconTile(systemName: entry.icon)
                                }
                            }
                            .accessibilityIdentifier("home.entry.\(entry.destination.featureID)")
                        }
                    } header: {
                        Text(section.section.title)
                    } footer: {
                        Text(section.section.subtitle)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
        .frame(maxWidth: horizontalSizeClass == .regular ? 680 : .infinity)
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .community:
            CommunityFeedView(viewModel: container.makeCommunityViewModel())
        case .topic:
            TopicView(viewModel: container.makeTopicViewModel())
        case .express:
            ExpressView(viewModel: container.makeExpressViewModel())
        case .delivery:
            DeliveryView(viewModel: container.makeDeliveryViewModel())
        case .photograph:
            PhotographView(viewModel: container.makePhotographViewModel())
        case .schedule:
            ScheduleView(viewModel: container.makeScheduleViewModel())
        case .grade:
            GradeView(viewModel: container.makeGradeViewModel())
        case .card:
            CardView(viewModel: container.makeCardViewModel())
        case .library:
            LibraryView(viewModel: container.makeLibraryViewModel())
        case .cet:
            CETView(viewModel: container.makeCETViewModel())
        case .evaluate:
            EvaluateView(viewModel: container.makeEvaluateViewModel())
        case .spare:
            SpareView(viewModel: container.makeSpareViewModel())
        case .graduateExam:
            GraduateExamView(viewModel: container.makeGraduateExamViewModel())
        case .news:
            NewsView(viewModel: container.makeNewsViewModel())
        case .dataCenter:
            DataCenterView()
        case .marketplace:
            MarketplaceView(viewModel: container.makeMarketplaceViewModel())
        case .lostFound:
            LostFoundView(viewModel: container.makeLostFoundViewModel())
        case .secret:
            SecretView(viewModel: container.makeSecretViewModel())
        case .dating:
            DatingView(viewModel: container.makeDatingViewModel())
        }
    }
}

private struct HomeTodayCoursesCard: View {
    let courses: [CourseItem]
    let isLoading: Bool
    let loadFailed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            if isLoading {
                ProgressView(localizedString("schedule.loading"))
                    .accessibilityIdentifier("home.todayCourses.loading")
            } else if loadFailed {
                Text(LocalizedStringKey("schedule.loadFailed"))
                    .foregroundStyle(DSColor.subtitle)
                    .accessibilityIdentifier("home.todayCourses.failed")
            } else if courses.isEmpty {
                Text(LocalizedStringKey("schedule.noCourses"))
                    .foregroundStyle(DSColor.subtitle)
                    .accessibilityIdentifier("home.todayCourses.empty")
            } else {
                ForEach(courses) { course in
                    HStack(alignment: .top, spacing: DSSpacing.sm) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DSColor.primary)
                            .frame(width: 3)
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text(course.courseName)
                                .font(.headline)
                                .foregroundStyle(DSColor.title)
                            Text(String(format: localizedString("schedule.sectionLocation"), course.startSection, course.endSection, course.location))
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("home.todayCourses.course.\(course.id)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.todayCourses")
    }
}

#Preview {
    let container = AppContainer.preview
    return HomeView(viewModel: HomeViewModel(repository: MockHomeRepository(), scheduleRepository: MockScheduleRepository()))
        .environmentObject(container)
}
