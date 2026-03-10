import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var container: AppContainer
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
            .sheet(item: $activeLocationPicker) { pickerField in
                ProfileLocationPickerSheet(
                    title: pickerField.title,
                    regions: viewModel.locationRegions,
                    onConfirm: { selection in
                        switch pickerField {
                        case .location:
                            viewModel.updateLocationSelection(selection)
                        case .hometown:
                            viewModel.updateHometownSelection(selection)
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

                            Button(viewModel.isEditing ? "取消" : "编辑") {
                                viewModel.isEditing ? viewModel.cancelEditing() : viewModel.startEditing()
                            }
                            .font(.subheadline.weight(.medium))
                        }

                        Divider()

                        if viewModel.isEditing {
                            editingSection
                        } else {
                            summarySection(profile)
                        }
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

    private var editingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            DSInputField(title: "昵称", placeholder: "请输入昵称", text: $viewModel.nickname)

            VStack(alignment: .leading, spacing: 8) {
                Text("生日")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DSColor.subtitle)

                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.birthdayDate },
                        set: { viewModel.updateBirthday(date: $0) }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)

                if !viewModel.birthday.isEmpty {
                    Button("清空生日") {
                        viewModel.clearBirthday()
                    }
                    .font(.footnote)
                }
            }

            selectionSection(
                title: "院系",
                currentValue: viewModel.college,
                options: viewModel.facultyOptions,
                onSelect: viewModel.selectCollege
            )

            selectionSection(
                title: "专业",
                currentValue: viewModel.major,
                options: viewModel.majorOptions,
                isDisabled: !viewModel.canSelectMajor,
                emptyMessage: "请先选择院系",
                onSelect: viewModel.selectMajor
            )

            selectionSection(
                title: "入学年份",
                currentValue: viewModel.grade.isEmpty ? "未选择" : viewModel.grade,
                options: viewModel.enrollmentOptions,
                onSelect: viewModel.selectEnrollment
            )

            locationRow(title: "国家 / 地区", value: viewModel.location) {
                activeLocationPicker = .location
            }

            locationRow(title: "家乡", value: viewModel.hometown) {
                activeLocationPicker = .hometown
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("个人简介")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DSColor.subtitle)

                TextField("一句话介绍自己...", text: $viewModel.bio, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let saveErrorMessage = viewModel.saveErrorMessage {
                Text(saveErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(DSColor.danger)
            }

            HStack(spacing: 10) {
                DSButton(title: "取消", variant: .secondary) {
                    viewModel.cancelEditing()
                }

                DSButton(
                    title: "保存资料",
                    icon: "checkmark",
                    isLoading: viewModel.isSaving,
                    isDisabled: !viewModel.isFormValid
                ) {
                    Task { await viewModel.saveProfile() }
                }
            }
        }
    }

    private func summarySection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            infoRow(title: "昵称", value: viewModel.displayText(profile.nickname, fallback: "点击设置"))
            infoRow(title: "生日", value: viewModel.displayText(profile.birthday, fallback: "未选择"))
            infoRow(title: "院系", value: viewModel.displayText(profile.college, fallback: "未选择"))
            infoRow(title: "专业", value: viewModel.displayText(profile.major, fallback: "未选择"))
            infoRow(title: "入学年份", value: viewModel.displayText(profile.grade, fallback: "未选择"))
            infoRow(title: "国家 / 地区", value: viewModel.displayText(profile.location, fallback: "未选择"))
            infoRow(title: "家乡", value: viewModel.displayText(profile.hometown, fallback: "未选择"))

            VStack(alignment: .leading, spacing: 6) {
                Text("个人简介")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DSColor.title)
                Text(viewModel.displayText(profile.bio, fallback: "去填写"))
                    .font(.subheadline)
                    .foregroundStyle(DSColor.subtitle)
            }
        }
    }

    private func selectionSection(
        title: String,
        currentValue: String,
        options: [String],
        isDisabled: Bool = false,
        emptyMessage: String? = nil,
        onSelect: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DSColor.subtitle)

            Menu {
                if isDisabled, let emptyMessage {
                    Text(emptyMessage)
                } else {
                    ForEach(options, id: \.self) { option in
                        Button(option) {
                            onSelect(option)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(currentValue.isEmpty ? "未选择" : currentValue)
                        .foregroundStyle(isDisabled ? DSColor.subtitle : DSColor.title)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(DSColor.subtitle)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isDisabled)
        }
    }

    private func locationRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DSColor.subtitle)

            Button(action: action) {
                HStack {
                    Text(viewModel.displayText(value, fallback: "未选择"))
                        .foregroundStyle(DSColor.title)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(DSColor.subtitle)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.locationRegions.isEmpty)
        }
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

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(DSColor.subtitle)

            Spacer(minLength: 16)

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DSColor.title)
                .multilineTextAlignment(.trailing)
        }
    }
}

private enum ProfileLocationPickerField: String, Identifiable {
    case location
    case hometown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location:
            return "选择国家 / 地区"
        case .hometown:
            return "选择家乡"
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
                }
            }
            .onAppear {
                syncSelectionIfNeeded()
            }
            .onChange(of: selectedRegionCode) { _, _ in
                syncStateAndCity()
            }
            .onChange(of: selectedStateCode) { _, _ in
                syncCityIfNeeded()
            }
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
        let stateName = currentState?.name ?? ""
        let cityName = currentCity?.name ?? ""
        return ProfileLocationSelection(
            displayName: ProfileFormSupport.makeLocationDisplay(
                region: currentRegion.name,
                state: stateName,
                city: cityName
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
