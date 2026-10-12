import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var isSchedulePresented = false
    @State private var isAllFunctionsPresented = false
    @State private var selectedDestination: AppDestination?
    @EnvironmentObject private var container: AppContainer
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    private var tokens = HomeDesignTokens()

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            contentView
            .navigationTitle(localizedString("home.title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $isSchedulePresented) {
                if let currentWeek = viewModel.currentSchedule?.weekIndex {
                    ScheduleView(viewModel: ScheduleViewModel(
                        repository: container.scheduleRepository,
                        initialWeekIndex: currentWeek
                    ))
                } else {
                    ScheduleView(viewModel: container.makeScheduleViewModel())
                }
            }
            .navigationDestination(isPresented: $isAllFunctionsPresented) {
                HomeAllFunctionsView { destination in
                    destinationView(for: destination)
                }
            }
            .navigationDestination(item: $selectedDestination) { destination in
                destinationView(for: destination)
            }
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
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    HStack {
                        Label(localizedString("schedule.todayCourses"), systemImage: "clock")
                            .font(tokens.headline)
                        Spacer()
                        Button {
                            isSchedulePresented = true
                        } label: {
                            Text(LocalizedStringKey("home.scheduleAction"))
                                .font(tokens.body)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.todayCourses.schedule")
                    }
                    .foregroundStyle(tokens.primary)
                    .frame(maxWidth: .infinity)

                    HomeTodayCoursesCard(
                        courses: viewModel.todayCourses,
                        isLoading: viewModel.isScheduleLoading || (viewModel.currentSchedule == nil && !viewModel.scheduleLoadFailed),
                        loadFailed: viewModel.scheduleLoadFailed
                    )
                }
                .padding(tokens.pageSpacing)
                .background(tokens.surface, in: RoundedRectangle(cornerRadius: tokens.cardRadius, style: .continuous))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                // Format before creating Text so the device environment cannot replace campus time.
                Text(HomeViewModel.campusDateDescription(on: viewModel.todayDate, locale: locale))
                    .font(tokens.caption)
                    .foregroundStyle(tokens.text2)
            }

            if viewModel.dashboard == nil, let error = viewModel.errorMessage {
                Section {
                    DSErrorStateView(message: error) {
                        Task { await viewModel.loadDashboard() }
                    }
                }
            }

            Section {
                VStack(spacing: 0) {
                    ForEach(HomeEntryConfig.commonEntries) { entry in
                        Button {
                            selectedDestination = entry.destination
                        } label: {
                            HomeServiceRow(entry: entry, showsSubtitle: false)
                                .padding(.vertical, DSSpacing.sm)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.entry.\(entry.destination.featureID)")
                        if entry.id != HomeEntryConfig.commonEntries.last?.id {
                            Divider()
                                .padding(.leading, tokens.iconSide + DSSpacing.sm)
                        }
                    }
                }
                .padding(.horizontal, tokens.pageSpacing)
                .background(tokens.surface, in: RoundedRectangle(cornerRadius: tokens.cardRadius, style: .continuous))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text(LocalizedStringKey("home.commonServices"))
                    .font(tokens.title.weight(.semibold))
                    .foregroundStyle(tokens.text1)
            }

            Section {
                Button {
                    isAllFunctionsPresented = true
                } label: {
                    Text(LocalizedStringKey("home.allFunctions"))
                        .font(tokens.headline.weight(.semibold))
                        .foregroundStyle(tokens.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, tokens.pageSpacing)
                        .background(tokens.primarySoft, in: RoundedRectangle(cornerRadius: tokens.cardRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home.allFunctions")
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(tokens.background.ignoresSafeArea())
        .contentMargins(.horizontal, tokens.pageSpacing, for: .scrollContent)
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
    private var tokens = HomeDesignTokens()

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            if isLoading {
                ProgressView(localizedString("schedule.loading"))
                    .accessibilityIdentifier("home.todayCourses.loading")
            } else if loadFailed {
                Text(LocalizedStringKey("schedule.loadFailed"))
                    .foregroundStyle(tokens.text2)
                    .accessibilityIdentifier("home.todayCourses.failed")
            } else if courses.isEmpty {
                Text(LocalizedStringKey("schedule.noCourses"))
                    .foregroundStyle(tokens.text2)
                    .accessibilityIdentifier("home.todayCourses.empty")
            } else {
                ForEach(courses) { course in
                    HStack(alignment: .top, spacing: DSSpacing.sm) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(tokens.primary)
                            .frame(width: 3)
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text(course.courseName)
                                .font(tokens.headline.weight(.semibold))
                                .foregroundStyle(tokens.text1)
                            Text(String(format: localizedString("schedule.sectionLocation"), course.startSection, course.endSection, course.location))
                                .font(tokens.body)
                                .foregroundStyle(tokens.text2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("home.todayCourses.course.\(course.id)")
                }
            }
        }
        .font(tokens.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.todayCourses")
    }
}

private struct HomeServiceRow: View {
    let entry: HomeEntryConfig
    let showsSubtitle: Bool
    private var tokens = HomeDesignTokens()

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            DSIconTile(
                systemName: entry.icon,
                size: tokens.iconSide,
                tint: showsSubtitle ? tokens.primary : tokens.onPrimary,
                background: showsSubtitle ? tokens.primarySoft : tokens.primary
            )
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(entry.title)
                    .font(tokens.body)
                    .foregroundStyle(tokens.text1)
                if showsSubtitle {
                    Text(entry.subtitle)
                        .font(tokens.callout)
                        .foregroundStyle(tokens.text2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(tokens.body)
                .foregroundStyle(tokens.text2)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct HomeAllFunctionsView<Destination: View>: View {
    let destination: (AppDestination) -> Destination
    @State private var selectedDestination: AppDestination?
    private var tokens = HomeDesignTokens()

    var body: some View {
        List {
            ForEach(HomeEntryConfig.allSections) { section in
                Section {
                    ForEach(section.entries) { entry in
                        Button {
                            selectedDestination = entry.destination
                        } label: {
                            HomeServiceRow(entry: entry, showsSubtitle: true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.entry.\(entry.destination.featureID)")
                        .listRowBackground(tokens.surface)
                    }
                } header: {
                    Text(section.section.title)
                        .font(tokens.headline)
                        .foregroundStyle(tokens.text2)
                } footer: {
                    Text(section.section.subtitle)
                        .font(tokens.caption)
                        .foregroundStyle(tokens.text2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(tokens.background.ignoresSafeArea())
        .contentMargins(.horizontal, tokens.pageSpacing, for: .scrollContent)
        .navigationTitle(localizedString("home.allFunctions"))
        .navigationDestination(item: $selectedDestination, destination: destination)
    }
}

/// Page 6's generated reference sizes, scaled using the matching native text curves.
/// Kept private to the audited Home screens; other app screens retain their styles.
private struct HomeDesignTokens: DynamicProperty {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize = GeneratedDesignTokens.displaySize
    @ScaledMetric(relativeTo: .title2) private var titleSize = GeneratedDesignTokens.titleSize
    @ScaledMetric(relativeTo: .headline) private var headlineSize = GeneratedDesignTokens.headlineSize
    @ScaledMetric(relativeTo: .body) private var bodySize = GeneratedDesignTokens.bodySize
    @ScaledMetric(relativeTo: .callout) private var calloutSize = GeneratedDesignTokens.calloutSize
    @ScaledMetric(relativeTo: .caption) private var captionSize = GeneratedDesignTokens.captionSize
    @ScaledMetric(relativeTo: .body) var iconSide: CGFloat = 28

    var display: Font { .system(size: displaySize) }
    var title: Font { .system(size: titleSize) }
    var headline: Font { .system(size: headlineSize) }
    var body: Font { .system(size: bodySize) }
    var callout: Font { .system(size: calloutSize) }
    var caption: Font { .system(size: captionSize) }
    var pageSpacing: CGFloat { GeneratedDesignTokens.pageSpacing }
    var cardRadius: CGFloat { GeneratedDesignTokens.cardRadius }

    var primary: Color { colorScheme == .dark ? GeneratedDesignTokens.Dark.primary : GeneratedDesignTokens.Light.primary }
    var primarySoft: Color { colorScheme == .dark ? GeneratedDesignTokens.Dark.primarySoft : GeneratedDesignTokens.Light.primarySoft }
    var background: Color { colorScheme == .dark ? GeneratedDesignTokens.Dark.bg : GeneratedDesignTokens.Light.bg }
    var surface: Color { colorScheme == .dark ? GeneratedDesignTokens.Dark.surface : GeneratedDesignTokens.Light.surface }
    var text1: Color { colorScheme == .dark ? GeneratedDesignTokens.Dark.text1 : GeneratedDesignTokens.Light.text1 }
    var text2: Color { colorScheme == .dark ? GeneratedDesignTokens.Dark.text2 : GeneratedDesignTokens.Light.text2 }
    var onPrimary: Color { colorScheme == .dark ? GeneratedDesignTokens.Dark.bg : GeneratedDesignTokens.Light.surface }
}

#Preview {
    let container = AppContainer.preview
    return HomeView(viewModel: HomeViewModel(repository: MockHomeRepository(), scheduleRepository: MockScheduleRepository()))
        .environmentObject(container)
}
