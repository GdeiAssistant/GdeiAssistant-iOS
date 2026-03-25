import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var container: AppContainer
    @State private var activeEditor: ProfileEditorField?
    @State private var activeLocationPicker: ProfileLocationPickerField?

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.displayProfile == nil {
                    DSLoadingView(text: "正在加载个人信息...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.displayProfile == nil {
                    DSErrorStateView(message: errorMessage) {
                        Task { await viewModel.loadProfile() }
                    }
                } else if let profile = viewModel.displayProfile {
                    profileContent(profile)
                } else {
                    DSEmptyStateView(
                        icon: "person.crop.circle",
                        title: "暂无个人资料",
                        message: "请稍后重试"
                    )
                }
            }
            .navigationTitle("个人中心")
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
                    onConfirm: { selection in
                        switch pickerField {
                        case .location:
                            viewModel.updateLocationSelection(selection)
                            Task { await viewModel.saveProfile() }
                        case .hometown:
                            viewModel.updateHometownSelection(selection)
                            Task { await viewModel.saveProfile() }
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
                        Text("账号资料")
                            .font(.headline)
                            .foregroundStyle(DSColor.title)

                        HStack(alignment: .top, spacing: 14) {
                            NavigationLink {
                                AvatarEditView(viewModel: container.makeAvatarEditViewModel())
                            } label: {
                                DSAvatarView(urlString: profile.avatarURL, size: 68)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.displayText(profile.nickname, fallback: "点击设置"))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(DSColor.title)

                                Text("用户名：\(profile.username)")
                                    .font(.caption)
                                    .foregroundStyle(DSColor.subtitle)

                                if !profile.ipArea.isEmpty {
                                    Text("IP 属地：\(profile.ipArea)")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                            }

                            Spacer()
                        }

                        Divider()

                        profileFields(profile)
                    }
                }

                Color.clear.frame(height: 36)

                DSCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("账号功能")
                            .font(.headline)
                            .foregroundStyle(DSColor.title)
                            .padding(.bottom, 10)

                        profileMenuLink(title: "隐私设置", systemImage: "lock.shield") {
                            PrivacySettingsView(viewModel: container.makePrivacySettingsViewModel())
                        }
                        Divider()
                        profileMenuLink(title: "登录记录", systemImage: "clock.arrow.circlepath") {
                            LoginRecordView(viewModel: container.makeLoginRecordViewModel())
                        }
                        Divider()
                        profileMenuLink(title: "绑定手机", systemImage: "phone") {
                            BindPhoneView(viewModel: container.makeBindPhoneViewModel())
                        }
                        Divider()
                        profileMenuLink(title: "绑定邮箱", systemImage: "envelope") {
                            BindEmailView(viewModel: container.makeBindEmailViewModel())
                        }
                        Divider()
                        profileMenuLink(title: "注销账号", systemImage: "person.crop.circle.badge.xmark") {
                            DeleteAccountView(viewModel: container.makeDeleteAccountViewModel())
                        }
                    }
                }

                Color.clear.frame(height: 24)

                DSCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("更多服务")
                            .font(.headline)
                            .foregroundStyle(DSColor.title)
                            .padding(.bottom, 10)

                        profileMenuLink(title: "下载个人数据", systemImage: "arrow.down.doc") {
                            DownloadDataView(viewModel: container.makeDownloadDataViewModel())
                        }
                        Divider()
                        profileMenuLink(title: "帮助与反馈", systemImage: "questionmark.bubble") {
                            FeedbackView(viewModel: container.makeFeedbackViewModel())
                        }
                        Divider()
                        profileMenuLink(title: "设置", systemImage: "gearshape") {
                            SettingsView(viewModel: container.makeSettingsViewModel())
                        }
                    }
                }

                Color.clear.frame(height: 20)

                DSButton(title: "退出账号", icon: "rectangle.portrait.and.arrow.right", variant: .destructive) {
                    Task {
                        await container.authManager.logout()
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .refreshable {
            await viewModel.loadProfile()
        }
    }

    private func profileFields(_ profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            editableRow(title: "昵称", value: viewModel.displayText(profile.nickname, fallback: "点击设置")) {
                activeEditor = .nickname
            }
            Divider().padding(.leading, 0)
            editableRow(title: "生日", value: viewModel.displayText(profile.birthday, fallback: "未设置")) {
                activeEditor = .birthday
            }
            Divider()
            editableRow(title: "院系", value: viewModel.displayText(profile.college, fallback: "未选择")) {
                activeEditor = .college
            }
            Divider()
            editableRow(title: "专业", value: viewModel.displayText(profile.major, fallback: "未选择")) {
                activeEditor = .major
            }
            Divider()
            editableRow(title: "入学年份", value: viewModel.displayText(profile.grade, fallback: "未选择")) {
                activeEditor = .grade
            }
            Divider()
            editableRow(title: "国家 / 地区", value: viewModel.displayText(profile.location, fallback: "未选择")) {
                activeLocationPicker = .location
            }
            Divider()
            editableRow(title: "家乡", value: viewModel.displayText(profile.hometown, fallback: "未选择")) {
                activeLocationPicker = .hometown
            }
            Divider()
            editableRow(title: "个人简介", value: viewModel.displayText(profile.bio, fallback: "去填写"), multiline: true) {
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

    private func profileMenuLink<Destination: View>(title: String, systemImage: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
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
        }
        .buttonStyle(.plain)
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
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var selectedDate = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                switch field {
                case .nickname:
                    Section {
                        TextField("请输入昵称", text: $text)
                    } header: {
                        Text("昵称")
                    }

                case .birthday:
                    Section {
                        DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.wheel)
                        Button("清空生日", role: .destructive) {
                            viewModel.clearBirthday()
                            Task { await save() }
                        }
                    } header: {
                        Text("生日")
                    }

                case .college:
                    Section {
                        ForEach(viewModel.facultyOptions, id: \.self) { option in
                            Button {
                                viewModel.selectCollege(option)
                                Task { await save() }
                            } label: {
                                HStack {
                                    Text(option).foregroundStyle(DSColor.title)
                                    Spacer()
                                    if viewModel.college == option {
                                        Image(systemName: "checkmark").foregroundStyle(DSColor.primary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("院系")
                    }

                case .major:
                    Section {
                        if !viewModel.canSelectMajor {
                            Text("请先选择院系")
                                .foregroundStyle(DSColor.subtitle)
                        } else {
                            ForEach(viewModel.majorOptions, id: \.self) { option in
                                Button {
                                    viewModel.selectMajor(option)
                                    Task { await save() }
                                } label: {
                                    HStack {
                                        Text(option).foregroundStyle(DSColor.title)
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
                        Text("专业")
                    }

                case .grade:
                    Section {
                        ForEach(viewModel.enrollmentOptions, id: \.self) { option in
                            Button {
                                viewModel.selectEnrollment(option)
                                Task { await save() }
                            } label: {
                                HStack {
                                    Text(option).foregroundStyle(DSColor.title)
                                    Spacer()
                                    let current = viewModel.grade.isEmpty ? "未选择" : viewModel.grade
                                    if current == option {
                                        Image(systemName: "checkmark").foregroundStyle(DSColor.primary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("入学年份")
                    }

                case .bio:
                    Section {
                        TextField("一句话介绍自己...", text: $text, axis: .vertical)
                            .lineLimit(4...8)
                    } header: {
                        Text("个人简介")
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
            .navigationTitle(field.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                if field.needsManualSave {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isSaving ? "保存中..." : "保存") {
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
            selectedDate = viewModel.birthdayDate
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
            viewModel.updateBirthday(date: selectedDate)
        case .bio:
            viewModel.bio = text
        default:
            break
        }

        isSaving = true
        errorMessage = nil
        let success = await viewModel.saveProfile()
        isSaving = false
        if success {
            dismiss()
        } else {
            errorMessage = viewModel.saveErrorMessage ?? "保存失败"
        }
    }
}

private extension ProfileEditorField {
    var title: String {
        switch self {
        case .nickname: return "昵称"
        case .birthday: return "生日"
        case .college: return "院系"
        case .major: return "专业"
        case .grade: return "入学年份"
        case .bio: return "个人简介"
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
        case .location: return "选择国家 / 地区"
        case .hometown: return "选择家乡"
        }
    }
}

private struct ProfileLocationPickerSheet: View {
    let title: String
    let regions: [ProfileLocationRegion]
    let onConfirm: (ProfileLocationSelection) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedRegionCode = ""
    @State private var selectedStateCode = ""
    @State private var selectedCityCode = ""

    var body: some View {
        NavigationStack {
            Group {
                if regions.isEmpty {
                    DSEmptyStateView(icon: "globe.asia.australia", title: "暂无地区数据", message: "请稍后重试")
                } else {
                    Form {
                        Picker("国家 / 地区", selection: $selectedRegionCode) {
                            ForEach(regions) { region in
                                Text(region.name).tag(region.code)
                            }
                        }

                        if !currentStates.isEmpty {
                            Picker("省 / 州", selection: $selectedStateCode) {
                                ForEach(currentStates) { state in
                                    Text(state.name).tag(state.code)
                                }
                            }
                        }

                        if !currentCities.isEmpty {
                            Picker("城市", selection: $selectedCityCode) {
                                ForEach(currentCities) { city in
                                    Text(city.name).tag(city.code)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("确定") {
                        guard let selection = currentSelection else { return }
                        onConfirm(selection)
                        dismiss()
                    }
                    .disabled(currentSelection == nil)
                    .fontWeight(.semibold)
                }
            }
            .onAppear { syncSelectionIfNeeded() }
            .onChange(of: selectedRegionCode) { _, _ in syncStateAndCity() }
            .onChange(of: selectedStateCode) { _, _ in syncCityIfNeeded() }
        }
    }

    private var currentRegion: ProfileLocationRegion? {
        regions.first(where: { $0.code == selectedRegionCode }) ?? regions.first
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

    private var currentSelection: ProfileLocationSelection? {
        guard let currentRegion else { return nil }
        return ProfileLocationSelection(
            displayName: ProfileFormSupport.makeLocationDisplay(
                region: currentRegion.name,
                state: currentState?.name ?? "",
                city: currentCity?.name ?? ""
            ),
            regionCode: currentRegion.code,
            stateCode: currentState?.code ?? "",
            cityCode: currentCity?.code ?? ""
        )
    }

    private func syncSelectionIfNeeded() {
        if selectedRegionCode.isEmpty {
            selectedRegionCode = regions.first?.code ?? ""
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
}

private extension ProfileViewModel {
    func displayText(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

#Preview {
    let container = AppContainer.preview
    return ProfileView(viewModel: ProfileViewModel(repository: MockProfileRepository(), sessionState: container.sessionState))
        .environmentObject(container)
}
