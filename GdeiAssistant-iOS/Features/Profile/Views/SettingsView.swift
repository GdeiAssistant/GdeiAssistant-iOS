import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ThemePickerView()
                } label: {
                    Label("主题色", systemImage: "paintpalette")
                }
                NavigationLink {
                    LanguagePickerView()
                } label: {
                    Label("语言", systemImage: "globe")
                }
            } header: {
                Text("外观")
            }

            Section {
                Toggle("使用模拟测试数据", isOn: mockBinding)
                    .disabled(!viewModel.isDebug)

                Text(viewModel.isDebug ? "开启后将读取本地 Mock 数据，便于离线测试。" : "当前为 Release 环境，不允许切换数据源。")
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)

                if viewModel.showReloadHint {
                    Text("切换已生效，部分页面可能需要重新加载。")
                        .font(.footnote)
                        .foregroundStyle(DSColor.warning)
                }
            } header: {
                Text("调试数据源")
            }

            Section {
                Picker("接口环境", selection: networkEnvironmentBinding) {
                    ForEach(NetworkEnvironment.allCases, id: \.self) { environment in
                        Text(environment.displayName).tag(environment)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!viewModel.isDebug)

                Text(viewModel.isDebug ? "真实接口支持 dev / staging / prod 三档切换，方便本地联调和灰度验证。" : "当前为 Release 环境，不允许切换接口环境。")
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text("接口环境")
            }

            if viewModel.isDebug {
                Section {
                    infoRow(title: "networkEnvironment", value: viewModel.networkEnvironmentText)
                    infoRow(title: "baseURL", value: viewModel.baseURLText)
                    infoRow(title: "dataSourceMode", value: viewModel.modeDisplayText)
                    infoRow(title: "X-Client-Type", value: viewModel.clientTypeText)
                    infoRow(title: "isDebug", value: viewModel.isDebug ? "true" : "false")
                } header: {
                    Text("调试信息")
                }
            }

            Section {
                VStack(spacing: 6) {
                    Text(AppConstants.Brand.displayName)
                    Text("iOS 客户端")
                        .font(.footnote)
                        .foregroundStyle(DSColor.subtitle)
                    Text("Copyright © GdeiAssistant 2016-2026")
                        .font(.footnote)
                        .foregroundStyle(DSColor.subtitle)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            } header: {
                Text("应用信息")
            }
        }
        .navigationTitle("设置")
    }

    private var mockBinding: Binding<Bool> {
        Binding(
            get: { viewModel.useMockData },
            set: { newValue in
                viewModel.updateMockEnabled(newValue)
            }
        )
    }

    private var networkEnvironmentBinding: Binding<NetworkEnvironment> {
        Binding(
            get: { viewModel.selectedNetworkEnvironment },
            set: { newValue in
                viewModel.updateNetworkEnvironment(newValue)
            }
        )
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DSColor.subtitle)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(DSColor.title)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let container = AppContainer.preview
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel(environment: container.environment, preferences: container.userPreferences))
    }
    .environmentObject(container)
    .environmentObject(container.userPreferences)
}
