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
            .navigationBarTitleDisplayMode(.inline)
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

    private var greetingTitle: String {
        if let user = container.sessionState.currentUser {
            let trimmedNickname = user.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmedNickname.isEmpty ? user.username : trimmedNickname
            if !name.isEmpty {
                return String(format: localizedString("home.greeting.named"), name)
            }
        }
        return localizedString("home.greeting.default")
    }

    private var contentView: some View {
        ScrollView {
            HStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    // Editorial masthead: campus date eyebrow, week badge, serif greeting, and motto.
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        HStack(alignment: .center, spacing: DSSpacing.sm) {
                            Text(HomeViewModel.campusDateDescription(on: viewModel.todayDate, locale: locale))
                                .font(tokens.caption.monospacedDigit())
                                .foregroundStyle(tokens.text2)

                            Spacer(minLength: DSSpacing.xs)

                            if let weekIndex = viewModel.currentSchedule?.weekIndex {
                                DSTag(
                                    text: String(format: localizedString("schedule.weekLabel"), weekIndex),
                                    tint: tokens.primary,
                                    background: tokens.primarySoft
                                )
                                .monospacedDigit()
                            }
                        }

                        Text(greetingTitle)
                            .font(DSTypography.displaySerif)
                            .foregroundStyle(tokens.text1)
                            .accessibilityAddTraits(.isHeader)

                        Text(LocalizedStringKey("home.editorial.subtitle"))
                            .font(tokens.callout)
                            .foregroundStyle(tokens.primary)
                    }
                    .padding(.top, DSSpacing.xs)

                    // Single elevated focal card on Warm Paper / Nocturnal Ink canvas.
                    DSCard(padding: tokens.pageSpacing, surfaceStyle: .elevated) {
                        HStack(alignment: .center, spacing: DSSpacing.sm) {
                            Label(localizedString("schedule.todayCourses"), systemImage: "clock")
                                .font(DSTypography.headlineSerif)
                                .foregroundStyle(tokens.text1)
                            Spacer()
                            Button {
                                isSchedulePresented = true
                            } label: {
                                HStack(spacing: DSSpacing.xxs) {
                                    Text(LocalizedStringKey("home.scheduleAction"))
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.semibold))
                                        .accessibilityHidden(true)
                                }
                                .font(tokens.callout.weight(.medium))
                                .foregroundStyle(tokens.primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("home.todayCourses.schedule")
                        }
                        .frame(maxWidth: .infinity)

                        DSHairlineDivider()

                        HomeTodayCoursesCard(
                            courses: viewModel.todayCourses,
                            isLoading: viewModel.isScheduleLoading || (viewModel.currentSchedule == nil && !viewModel.scheduleLoadFailed),
                            loadFailed: viewModel.scheduleLoadFailed
                        )
                    }

                    // Borderless Campus Services index directly on canvas with 1pt hairline dividers.
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(LocalizedStringKey("home.commonServices"))
                            .font(DSTypography.title2Serif)
                            .foregroundStyle(tokens.text1)
                            .accessibilityAddTraits(.isHeader)

                        DSHairlineDivider(thickness: 1, color: DSColor.border)

                        VStack(spacing: 0) {
                            ForEach(HomeEntryConfig.commonEntries) { entry in
                                Button {
                                    selectedDestination = entry.destination
                                } label: {
                                    HomeServiceRow(entry: entry, showsSubtitle: false)
                                        .padding(.vertical, DSSpacing.sm)
                                }
                                .buttonStyle(DSPressableButtonStyle())
                                .accessibilityIdentifier("home.entry.\(entry.destination.featureID)")

                                if entry.id != HomeEntryConfig.commonEntries.last?.id {
                                    DSHairlineDivider(leadingInset: tokens.iconSide + DSSpacing.sm)
                                }
                            }
                        }
                    }

                    Button {
                        isAllFunctionsPresented = true
                    } label: {
                        HStack(spacing: DSSpacing.sm) {
                            Text(LocalizedStringKey("home.allFunctions"))
                                .font(DSTypography.headlineSerif)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.semibold))
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(tokens.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, tokens.pageSpacing)
                        .padding(.vertical, tokens.pageSpacing)
                        .background(tokens.surface, in: RoundedRectangle(cornerRadius: tokens.cardRadius, style: .continuous))
                        .dsHairlineBorder(tokens.cardRadius, color: DSColor.border)
                    }
                    .buttonStyle(DSPressableButtonStyle())
                    .accessibilityIdentifier("home.allFunctions")

                    VStack(spacing: DSSpacing.xs) {
                        DSHairlineDivider()
                        Text(LocalizedStringKey("home.footer.colophon"))
                            .font(tokens.caption)
                            .foregroundStyle(DSColor.tertiaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, DSSpacing.xs)
                }
                .padding(.horizontal, tokens.pageSpacing)
                .padding(.vertical, DSSpacing.sm)
                .frame(maxWidth: horizontalSizeClass == .regular ? 680 : .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
        }
        .background(tokens.background.ignoresSafeArea())
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

    init(courses: [CourseItem], isLoading: Bool, loadFailed: Bool) {
        self.courses = courses
        self.isLoading = isLoading
        self.loadFailed = loadFailed
    }

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
                                .font(tokens.body.monospacedDigit())
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

    init(entry: HomeEntryConfig, showsSubtitle: Bool) {
        self.entry = entry
        self.showsSubtitle = showsSubtitle
    }

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            DSIconTile(
                systemName: entry.icon,
                size: tokens.iconSide,
                tint: tokens.primary,
                background: tokens.primarySoft
            )
            .dsHairlineBorder(7, color: tokens.primary.opacity(0.2))
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(entry.title)
                    .font(tokens.body.weight(.medium))
                    .foregroundStyle(tokens.text1)
                if showsSubtitle {
                    Text(entry.subtitle)
                        .font(tokens.callout)
                        .foregroundStyle(tokens.text2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DSColor.tertiaryText)
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

    init(@ViewBuilder destination: @escaping (AppDestination) -> Destination) {
        self.destination = destination
    }

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
                        .font(DSTypography.headlineSerif)
                        .foregroundStyle(tokens.text1)
                        .textCase(nil)
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

/// Page 6's generated reference sizes, scaled using the matching native text curves
/// and synchronized with the active Lingnan campus accent.
private struct HomeDesignTokens: DynamicProperty {
    @Environment(\.dsCampusAccent) private var campusAccent
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

    var primary: Color { campusAccent.primary }
    var primarySoft: Color { campusAccent.primarySoft }
    var background: Color { DSColor.background }
    var surface: Color { DSColor.surface }
    var text1: Color { DSColor.title }
    var text2: Color { DSColor.subtitle }
    var onPrimary: Color { campusAccent.onPrimary }
}

#if DEBUG
#Preview {
    let container = AppContainer.preview
    return HomeView(viewModel: HomeViewModel(scheduleRepository: MockScheduleRepository()))
        .environmentObject(container)
}
#endif
