import SwiftUI

struct PrivacySettingsView: View {
    @StateObject private var viewModel: PrivacySettingsViewModel

    init(viewModel: PrivacySettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                toggleRow("公开我的院系", value: viewModel.settings.facultyOpen) { value in
                    await viewModel.update { $0.facultyOpen = value }
                }
                toggleRow("公开我的专业", value: viewModel.settings.majorOpen) { value in
                    await viewModel.update { $0.majorOpen = value }
                }
                toggleRow("公开我的个人简介", value: viewModel.settings.introductionOpen) { value in
                    await viewModel.update { $0.introductionOpen = value }
                }
                toggleRow("公开我的入学年份", value: viewModel.settings.enrollmentOpen) { value in
                    await viewModel.update { $0.enrollmentOpen = value }
                }
                toggleRow("公开我的国家/地区", value: viewModel.settings.locationOpen) { value in
                    await viewModel.update { $0.locationOpen = value }
                }
                toggleRow("公开我的家乡", value: viewModel.settings.hometownOpen) { value in
                    await viewModel.update { $0.hometownOpen = value }
                }
                toggleRow("公开我的年龄", value: viewModel.settings.ageOpen) { value in
                    await viewModel.update { $0.ageOpen = value }
                }
                toggleRow("缓存我的教务数据", value: viewModel.settings.cacheAllow) { value in
                    await viewModel.update { $0.cacheAllow = value }
                }
                toggleRow("允许搜索引擎收录个人页", value: viewModel.settings.robotsIndexAllow) { value in
                    await viewModel.update { $0.robotsIndexAllow = value }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            }
        }
        .navigationTitle("隐私设置")
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                ProgressView("正在加载...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .task {
            await viewModel.load()
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.successMessage = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }

    private func toggleRow(_ title: String, value: Bool, action: @escaping (Bool) async -> Void) -> some View {
        Toggle(title, isOn: Binding(
            get: { value },
            set: { newValue in
                Task { await action(newValue) }
            }
        ))
        .disabled(viewModel.isSaving)
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView(viewModel: PrivacySettingsViewModel(repository: MockAccountCenterRepository()))
    }
}
