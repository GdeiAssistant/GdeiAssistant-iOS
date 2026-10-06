import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var container: AppContainer
    @Environment(\.locale) private var locale
    @State private var activeEditor: ProfileEditorField?
    @State private var activeLocationPicker: ProfileLocationPickerField?

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.displayProfile == nil {
                    DSLoadingView(text: localizedString("profile.loading"))
                } else if let errorMessage = viewModel.errorMessage, viewModel.displayProfile == nil {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.loadProfile() }
                    }
                } else if let profile = viewModel.displayProfile {
                    profileContent(profile)
                } else {
                    DSEmptyStateView(
                        icon: "person.crop.circle",
                        title: localizedString("profile.emptyTitle"),
                        message: localizedString("profile.emptyMsg")
                    )
                }
            }
            .navigationTitle(localizedString("profile.center", locale: locale.identifier))
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadIfNeeded()
            }
            .sheet(item: $activeEditor) { field in
                ProfileFieldEditorSheet(
                    field: field,
                    viewModel: viewModel
                )
            }
            .sheet(item: $activeLocationPicker) { pickerField in
                ProfileLocationPickerSheet(
                    title: pickerField.title,
                    regions: viewModel.locationRegions,
                    currentSelection: {
                        switch pickerField {
                        case .location:
                            return viewModel.displayProfile?.locationSelection
                        case .hometown:
                            return viewModel.displayProfile?.hometownSelection
                        }
                    }(),
                    onConfirm: { selection in
                        switch pickerField {
                        case .location:
                            viewModel.updateLocationSelection(selection)
                            return ProfileSaveResult.from(
                                didSave: await viewModel.saveProfile(),
                                errorMessage: viewModel.saveErrorMessage
                            )
                        case .hometown:
                            viewModel.updateHometownSelection(selection)
                            return ProfileSaveResult.from(
                                didSave: await viewModel.saveProfile(),
                                errorMessage: viewModel.saveErrorMessage
                            )
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func profileContent(_ profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                DSCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localizedString("profile.accountInfo"))
                            .font(.headline)
                            .foregroundStyle(DSColor.title)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 14) {
                                NavigationLink {
                                    AvatarEditView(viewModel: container.makeAvatarEditViewModel())
                                } label: {
                                    DSAvatarView(urlString: profile.avatarURL, size: 68)
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.displayText(profile.nickname, fallback: localizedString("profile.tapToSet")))
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(DSColor.title)

                                    Text("\(localizedString("profile.usernameLabel"))\(profile.username)")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)

                                    if !profile.ipArea.isEmpty {
                                        Text("\(localizedString("profile.ipAreaLabel"))\(ProfileLocationCatalog.areaDisplayName(profile.ipArea, localeIdentifier: locale.identifier))")
                                            .font(.caption)
                                            .foregroundStyle(DSColor.subtitle)
                                    }
                                }

                                Spacer()
                            }

                            SocialProfileStatsRow(viewModel: container.makeSocialMeSummaryViewModel())
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("profile.header")

                        Divider()

                        profileFields(profile)
                    }
                }

                Color.clear.frame(height: 24)

                DSCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(localizedString("profile.accountFunctions"))
                            .font(.headline)
                            .foregroundStyle(DSColor.title)
                            .padding(.bottom, 10)

                        profileMenuLink(title: localizedString("social.search.title"), systemImage: "magnifyingglass") {
                            SocialUserSearchView(viewModel: container.makeSocialUserSearchViewModel())
                        }
                        Divider()
                        profileMenuLink(title: localizedString("social.conversations.title"), systemImage: "bubble.left.and.bubble.right") {
                            ConversationListView(viewModel: container.makeConversationListViewModel())
                        }
                        Divider()
                        profileMenuLink(
                            title: localizedString("profile.privacySettings"),
                            systemImage: "lock.shield",
                            accessibilityIdentifier: "profile.entry.privacy"
                        ) {
                            PrivacySettingsView(viewModel: container.makePrivacySettingsViewModel())
                        }
                        Divider()
                        profileMenuLink(title: localizedString("profile.campusCredential"), systemImage: "key") {
                            CampusCredentialView(viewModel: container.makeCampusCredentialViewModel())
                                .environmentObject(container.environment)
                        }
                        Divider()
                        profileMenuLink(title: localizedString("profile.loginRecord"), systemImage: "clock.arrow.circlepath") {
                            LoginRecordView(viewModel: container.makeLoginRecordViewModel())
                        }
                        Divider()
                        profileMenuLink(title: localizedString("profile.bindPhone"), systemImage: "phone") {
                            BindPhoneView(viewModel: container.makeBindPhoneViewModel())
                        }
                        Divider()
                        profileMenuLink(title: localizedString("profile.bindEmail"), systemImage: "envelope") {
                            BindEmailView(viewModel: container.makeBindEmailViewModel())
                        }
                        Divider()
                        profileMenuLink(title: localizedString("profile.deleteAccount"), systemImage: "person.crop.circle.badge.xmark") {
                            DeleteAccountView(viewModel: container.makeDeleteAccountViewModel())
                        }
                    }
                }

                Color.clear.frame(height: 24)

                DSCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(localizedString("profile.moreServices"))
                            .font(.headline)
                            .foregroundStyle(DSColor.title)
                            .padding(.bottom, 10)

                        profileMenuLink(
                            title: localizedString("appearance.title"),
                            systemImage: "paintbrush",
                            accessibilityIdentifier: "profile.entry.appearance"
                        ) {
                            AppearanceView()
                        }
                        Divider()
                        profileMenuLink(title: localizedString("profile.downloadData"), systemImage: "arrow.down.doc") {
                            DownloadDataView(viewModel: container.makeDownloadDataViewModel())
                        }
                        Divider()
                        profileMenuLink(title: localizedString("profile.helpFeedback"), systemImage: "questionmark.bubble") {
                            FeedbackView(viewModel: container.makeFeedbackViewModel())
                        }
                        Divider()
                        profileMenuLink(title: localizedString("profile.settings"), systemImage: "gearshape") {
                            SettingsView(viewModel: container.makeSettingsViewModel())
                        }
                    }
                }

                Color.clear.frame(height: 20)

                DSButton(title: localizedString("profile.logout"), icon: "rectangle.portrait.and.arrow.right", variant: .destructive) {
                    Task {
                        await container.authManager.logout()
                    }
                }
            }
            .padding(16)
        }
        .dsScreenBackground()
        .refreshable {
            await viewModel.loadProfile()
        }
    }

    private func profileFields(_ profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            editableRow(title: localizedString("profile.nickname"), value: viewModel.displayText(profile.nickname, fallback: localizedString("profile.tapToSet"))) {
                activeEditor = .nickname
            }
            Divider().padding(.leading, 0)
            editableRow(title: localizedString("profile.birthday"), value: viewModel.displayText(profile.birthday, fallback: localizedString("profile.notSet"))) {
                activeEditor = .birthday
            }
            Divider()
            editableRow(title: localizedString("profile.faculty"), value: viewModel.displayText(profile.collegeDisplayName(localeIdentifier: locale.identifier), fallback: localizedString("profile.notSelected"))) {
                activeEditor = .college
            }
            Divider()
            editableRow(title: localizedString("profile.major"), value: viewModel.displayText(profile.majorDisplayName(localeIdentifier: locale.identifier), fallback: localizedString("profile.notSelected"))) {
                activeEditor = .major
            }
            Divider()
            editableRow(title: localizedString("profile.enrollment"), value: viewModel.displayText(profile.grade, fallback: localizedString("profile.notSelected"))) {
                activeEditor = .grade
            }
            Divider()
            editableRow(title: localizedString("profile.country"), value: viewModel.displayText(profile.locationDisplayName(localeIdentifier: locale.identifier), fallback: localizedString("profile.notSelected"))) {
                activeLocationPicker = .location
            }
            Divider()
            editableRow(title: localizedString("profile.hometown"), value: viewModel.displayText(profile.hometownDisplayName(localeIdentifier: locale.identifier), fallback: localizedString("profile.notSelected"))) {
                activeLocationPicker = .hometown
            }
            Divider()
            editableRow(title: localizedString("profile.bio"), value: viewModel.displayText(profile.bio, fallback: localizedString("profile.goWrite")), multiline: true) {
                activeEditor = .bio
            }
        }
    }

    private func editableRow(title: String, value: String, multiline: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: multiline ? .top : .center) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(DSColor.subtitle)
                    .frame(width: 80, alignment: .leading)

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(DSColor.title)
                    .multilineTextAlignment(.leading)
                    .lineLimit(multiline ? 3 : 1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func profileMenuLink<Destination: View>(
        title: String,
        systemImage: String,
        accessibilityIdentifier: String? = nil,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        let link = NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(DSColor.primary)
                    .frame(width: 20, alignment: .center)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(DSColor.title)

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(DSColor.subtitle)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if let accessibilityIdentifier {
            link.accessibilityIdentifier(accessibilityIdentifier)
        } else {
            link
        }
    }
}

// MARK: - Editor field enum

private enum ProfileEditorField: String, Identifiable {
    case nickname, birthday, college, major, grade, bio
    var id: String { rawValue }
}

// MARK: - Field editor sheet

private struct ProfileFieldEditorSheet: View {
    let field: ProfileEditorField
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var selectedDate = Date()
    @State private var hadExistingBirthday = false
    @State private var didChangeBirthdaySelection = false
    @State private var didRequestBirthdayClear = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                switch field {
                case .nickname:
                    Section {
                        TextField(localizedString("profile.nicknamePlaceholder"), text: $text)
                    } header: {
                        Text(localizedString("profile.nickname"))
                    }

                case .birthday:
                    Section {
                        DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.wheel)
                            .onChange(of: selectedDate) { _, _ in
                                didChangeBirthdaySelection = true
                                didRequestBirthdayClear = false
                            }
                        Button(localizedString("profile.clearBirthday"), role: .destructive) {
                            didRequestBirthdayClear = true
                            Task { await save() }
                        }
                    } header: {
                        Text(localizedString("profile.birthday"))
                    }

                case .college:
                    Section {
                        ForEach(viewModel.facultyOptions, id: \.self) { option in
                            Button {
                                viewModel.selectCollege(option)
                                Task { await save() }
                            } label: {
                                HStack {
                                    Text(viewModel.displaySelectionOption(option, localeIdentifier: locale.identifier)).foregroundStyle(DSColor.title)
                                    Spacer()
                                    if viewModel.college == option {
                                        Image(systemName: "checkmark").foregroundStyle(DSColor.primary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(localizedString("profile.faculty"))
                    }

                case .major:
                    Section {
                        if !viewModel.canSelectMajor {
                            Text(localizedString("profile.selectFacultyFirst"))
                                .foregroundStyle(DSColor.subtitle)
                        } else {
                            ForEach(viewModel.majorOptions, id: \.self) { option in
                                Button {
                                    viewModel.selectMajor(option)
                                    Task { await save() }
                                } label: {
                                    HStack {
                                        Text(viewModel.displaySelectionOption(option, localeIdentifier: locale.identifier)).foregroundStyle(DSColor.title)
                                        Spacer()
                                        if viewModel.major == option {
                                            Image(systemName: "checkmark").foregroundStyle(DSColor.primary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } header: {
                        Text(localizedString("profile.major"))
                    }

                case .grade:
                    Section {
                        ForEach(viewModel.enrollmentOptions, id: \.self) { option in
                            Button {
                                viewModel.selectEnrollment(option)
                                Task { await save() }
                            } label: {
                                HStack {
                                    Text(viewModel.displaySelectionOption(option, localeIdentifier: locale.identifier)).foregroundStyle(DSColor.title)
                                    Spacer()
                                    if viewModel.isEnrollmentOptionSelected(option) {
                                        Image(systemName: "checkmark").foregroundStyle(DSColor.primary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(localizedString("profile.enrollment"))
                    }

                case .bio:
                    Section {
                        TextField(localizedString("profile.bioPlaceholder"), text: $text, axis: .vertical)
                            .lineLimit(4...8)
                    } header: {
                        Text(localizedString("profile.bio"))
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(DSColor.danger)
                            .font(.footnote)
                    }
                }
            }
            .dsListBackground()
            .navigationTitle(field.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedString("common.cancel")) { dismiss() }
                }
                if field.needsManualSave {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isSaving ? localizedString("common.saving") : localizedString("common.save")) {
                            Task { await save() }
                        }
                        .disabled(isSaving)
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear { syncInitialValues() }
        }
    }

    private func syncInitialValues() {
        switch field {
        case .nickname:
            text = viewModel.nickname
        case .birthday:
            hadExistingBirthday = !FormValidationSupport.trimmed(viewModel.birthday).isEmpty
            didChangeBirthdaySelection = false
            selectedDate = viewModel.birthdayDate
            didRequestBirthdayClear = false
        case .bio:
            text = viewModel.bio
        default:
            break
        }
    }

    private func save() async {
        switch field {
        case .nickname:
            viewModel.nickname = text
        case .birthday:
            viewModel.applyBirthdayEditorChange(
                selectedDate: selectedDate,
                hadExistingBirthday: hadExistingBirthday,
                didChangeSelection: didChangeBirthdaySelection,
                didRequestClear: didRequestBirthdayClear
            )
        case .bio:
            viewModel.bio = text
        default:
            break
        }

        isSaving = true
        errorMessage = nil
        let result = ProfileSaveResult.from(
            didSave: await viewModel.saveProfile(),
            errorMessage: viewModel.saveErrorMessage
        )
        isSaving = false
        switch result {
        case .success:
            dismiss()
        case .failure(let message):
            errorMessage = message
        }
    }
}

private extension ProfileEditorField {
    var title: String {
        switch self {
        case .nickname: return localizedString("profile.nickname")
        case .birthday: return localizedString("profile.birthday")
        case .college: return localizedString("profile.faculty")
        case .major: return localizedString("profile.major")
        case .grade: return localizedString("profile.enrollment")
        case .bio: return localizedString("profile.bio")
        }
    }

    // Fields that need an explicit Save button (vs auto-save on selection)
    var needsManualSave: Bool {
        self == .nickname || self == .birthday || self == .bio
    }
}

// MARK: - Location picker

private enum ProfileLocationPickerField: String, Identifiable {
    case location
    case hometown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location: return localizedString("profile.selectCountry")
        case .hometown: return localizedString("profile.selectHometown")
        }
    }
}

private struct ProfileLocationPickerSheet: View {
    let title: String
    let regions: [ProfileLocationRegion]
    let currentSelection: ProfileLocationSelection?
    let onConfirm: (ProfileLocationSelection) async -> ProfileSaveResult

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var selectedRegionCode = ""
    @State private var selectedStateCode = ""
    @State private var selectedCityCode = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if localizedRegions.isEmpty {
                    DSEmptyStateView(icon: "globe.asia.australia", title: localizedString("profile.noLocationData"), message: localizedString("profile.emptyMsg"))
                } else {
                    Form {
                        Picker(localizedString("profile.regionPicker"), selection: $selectedRegionCode) {
                            ForEach(localizedRegions) { region in
                                Text(region.name).tag(region.code)
                            }
                        }

                        if !currentStates.isEmpty {
                            Picker(localizedString("profile.statePicker"), selection: $selectedStateCode) {
                                ForEach(currentStates) { state in
                                    Text(state.name).tag(state.code)
                                }
                            }
                        }

                        if !currentCities.isEmpty {
                            Picker(localizedString("profile.cityPicker"), selection: $selectedCityCode) {
                                ForEach(currentCities) { city in
                                    Text(city.name).tag(city.code)
                                }
                            }
                        }

                        if let errorMessage {
                            Section {
                                Text(errorMessage)
                                    .foregroundStyle(DSColor.danger)
                                    .font(.footnote)
                            }
                        }
                    }
                    .dsListBackground()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localizedString("common.cancel")) { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? localizedString("common.saving") : localizedString("profile.confirm")) {
                        guard let selection = selectedLocation else { return }
                        Task { await confirm(selection) }
                    }
                    .disabled(selectedLocation == nil || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .onAppear { syncSelectionIfNeeded() }
            .onChange(of: selectedRegionCode) { _, _ in syncStateAndCity() }
            .onChange(of: selectedStateCode) { _, _ in syncCityIfNeeded() }
        }
    }

    private var localizedRegions: [ProfileLocationRegion] {
        ProfileLocationCatalog.localizing(regions, localeIdentifier: locale.identifier)
    }

    private var currentRegion: ProfileLocationRegion? {
        localizedRegions.first(where: { $0.code == selectedRegionCode }) ?? localizedRegions.first
    }

    private var currentStates: [ProfileLocationState] {
        currentRegion?.states ?? []
    }

    private var currentState: ProfileLocationState? {
        currentStates.first(where: { $0.code == selectedStateCode }) ?? currentStates.first
    }

    private var currentCities: [ProfileLocationCity] {
        currentState?.cities ?? []
    }

    private var currentCity: ProfileLocationCity? {
        currentCities.first(where: { $0.code == selectedCityCode }) ?? currentCities.first
    }

    private var selectedLocation: ProfileLocationSelection? {
        guard let currentRegion else { return nil }
        return ProfileLocationSelection(
            displayName: ProfileFormSupport.makeLocationDisplay(
                region: currentRegion.name,
                state: currentState?.name ?? "",
                city: currentCity?.name ?? "",
                localeIdentifier: locale.identifier
            ),
            regionCode: currentRegion.code,
            stateCode: currentState?.code ?? "",
            cityCode: currentCity?.code ?? ""
        )
    }

    private func syncSelectionIfNeeded() {
        if selectedRegionCode.isEmpty {
            selectedRegionCode = resolvedSelection?.regionCode ?? regions.first?.code ?? ""
        }
        if selectedStateCode.isEmpty {
            selectedStateCode = resolvedSelection?.stateCode ?? ""
        }
        if selectedCityCode.isEmpty {
            selectedCityCode = resolvedSelection?.cityCode ?? ""
        }
        syncStateAndCity()
    }

    private func syncStateAndCity() {
        if !currentStates.contains(where: { $0.code == selectedStateCode }) {
            selectedStateCode = currentStates.first?.code ?? ""
        }
        syncCityIfNeeded()
    }

    private func syncCityIfNeeded() {
        if !currentCities.contains(where: { $0.code == selectedCityCode }) {
            selectedCityCode = currentCities.first?.code ?? ""
        }
    }

    private func confirm(_ selection: ProfileLocationSelection) async {
        isSaving = true
        errorMessage = nil
        let result = await onConfirm(selection)
        isSaving = false

        switch result {
        case .success:
            dismiss()
        case .failure(let message):
            errorMessage = message
        }
    }

    private var resolvedSelection: ProfileLocationSelection? {
        guard let currentSelection else { return nil }
        guard let region = localizedRegions.first(where: { $0.code == currentSelection.regionCode }) else {
            return nil
        }
        if currentSelection.stateCode.isEmpty {
            return currentSelection
        }
        guard let state = region.states.first(where: { $0.code == currentSelection.stateCode }) else {
            return nil
        }
        if currentSelection.cityCode.isEmpty {
            return currentSelection
        }
        guard state.cities.contains(where: { $0.code == currentSelection.cityCode }) else {
            return nil
        }
        return currentSelection
    }
}

private extension ProfileViewModel {
    func displayText(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == ProfileFormSupport.unselectedOption ? fallback : trimmed
    }

    func displaySelectionOption(_ value: String, localeIdentifier: String) -> String {
        selectionOptionDisplayName(value, localeIdentifier: localeIdentifier)
    }
}

private struct SocialProfileStatsRow: View {
    @EnvironmentObject private var container: AppContainer
    @Environment(\.locale) private var locale
    @StateObject private var viewModel: SocialMeSummaryViewModel

    init(viewModel: SocialMeSummaryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.me == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
            } else if let me = viewModel.me {
                HStack(spacing: 12) {
                    statItem(
                        title: localizedString("social.relationship.following", locale: locale.identifier),
                        value: me.followingCount,
                        kind: .following,
                        userID: me.id,
                        accessibilityIdentifier: "profile.stats.following"
                    )
                    statItem(
                        title: localizedString("social.relationship.followers", locale: locale.identifier),
                        value: me.followerCount,
                        kind: .followers,
                        userID: me.id,
                        accessibilityIdentifier: "profile.stats.followers"
                    )
                    statItem(
                        title: localizedString("social.relationship.friends", locale: locale.identifier),
                        value: me.friendCount,
                        kind: .friends,
                        userID: me.id,
                        accessibilityIdentifier: "profile.stats.friends"
                    )
                }
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(DSColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func statItem(
        title: String,
        value: Int,
        kind: SocialRelationshipKind,
        userID: String,
        accessibilityIdentifier: String
    ) -> some View {
        NavigationLink {
            SocialRelationshipListView(
                viewModel: container.makeSocialRelationshipListViewModel(userID: userID, kind: kind)
            )
        } label: {
            VStack(spacing: 4) {
                Text("\(value)")
                    .font(.headline)
                    .foregroundStyle(DSColor.title)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(DSColor.subtitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview {
    let container = AppContainer.preview
    return ProfileView(viewModel: ProfileViewModel(repository: MockProfileRepository(), sessionState: container.sessionState))
        .environmentObject(container)
}
