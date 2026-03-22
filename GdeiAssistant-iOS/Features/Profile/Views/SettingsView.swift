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
                    AppearanceView()
                } label: {
                    Label(LocalizedStringKey("appearance.title"), systemImage: "paintbrush")
                }
            } header: {
                Text(LocalizedStringKey("appearance.title"))
            }

            Section {
                Toggle(LocalizedStringKey("settings.useMockData"), isOn: mockBinding)
                    .disabled(!viewModel.isDebug)

                Text(LocalizedStringKey(viewModel.isDebug ? "settings.mockDataEnabled" : "settings.mockDataDisabled"))
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)

                if viewModel.showReloadHint {
                    Text(LocalizedStringKey("settings.reloadHint"))
                        .font(.footnote)
                        .foregroundStyle(DSColor.warning)
                }
            } header: {
                Text(LocalizedStringKey("settings.debugDataSource"))
            }

            Section {
                Picker(LocalizedStringKey("settings.apiEnvironmentLabel"), selection: networkEnvironmentBinding) {
                    ForEach(NetworkEnvironment.allCases, id: \.self) { environment in
                        Text(environment.displayName).tag(environment)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!viewModel.isDebug)

                Text(LocalizedStringKey(viewModel.isDebug ? "settings.apiDebugHint" : "settings.apiReleaseHint"))
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text(LocalizedStringKey("settings.apiEnvironment"))
            }

            if viewModel.isDebug {
                Section {
                    infoRow(title: "networkEnvironment", value: viewModel.networkEnvironmentText)
                    infoRow(title: "baseURL", value: viewModel.baseURLText)
                    infoRow(title: "dataSourceMode", value: viewModel.modeDisplayText)
                    infoRow(title: "X-Client-Type", value: viewModel.clientTypeText)
                    infoRow(title: "isDebug", value: viewModel.isDebug ? "true" : "false")
                } header: {
                    Text(LocalizedStringKey("settings.debugInfo"))
                }
            }

            Section {
                VStack(spacing: 6) {
                    Text(AppConstants.Brand.displayName)
                    Text(LocalizedStringKey("settings.iOSClient"))
                        .font(.footnote)
                        .foregroundStyle(DSColor.subtitle)
                    Text("Copyright \u{00A9} GdeiAssistant 2016-2026")
                        .font(.footnote)
                        .foregroundStyle(DSColor.subtitle)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            } header: {
                Text(LocalizedStringKey("settings.appInfo"))
            }
        }
        .navigationTitle(localizedString("settings.title"))
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
