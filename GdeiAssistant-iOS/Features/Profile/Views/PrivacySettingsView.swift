import SwiftUI

struct PrivacySettingsView: View {
    @StateObject private var viewModel: PrivacySettingsViewModel

    init(viewModel: PrivacySettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                toggleRow(localizedString("privacy.faculty"), value: viewModel.settings.facultyOpen) { value in
                    await viewModel.update { $0.facultyOpen = value }
                }
                toggleRow(localizedString("privacy.major"), value: viewModel.settings.majorOpen) { value in
                    await viewModel.update { $0.majorOpen = value }
                }
                toggleRow(localizedString("privacy.intro"), value: viewModel.settings.introductionOpen) { value in
                    await viewModel.update { $0.introductionOpen = value }
                }
                toggleRow(localizedString("privacy.enrollment"), value: viewModel.settings.enrollmentOpen) { value in
                    await viewModel.update { $0.enrollmentOpen = value }
                }
                toggleRow(localizedString("privacy.location"), value: viewModel.settings.locationOpen) { value in
                    await viewModel.update { $0.locationOpen = value }
                }
                toggleRow(localizedString("privacy.hometown"), value: viewModel.settings.hometownOpen) { value in
                    await viewModel.update { $0.hometownOpen = value }
                }
                toggleRow(localizedString("privacy.age"), value: viewModel.settings.ageOpen) { value in
                    await viewModel.update { $0.ageOpen = value }
                }
                toggleRow(localizedString("privacy.cache"), value: viewModel.settings.cacheAllow) { value in
                    await viewModel.update { $0.cacheAllow = value }
                }
                toggleRow(localizedString("privacy.robotsIndex"), value: viewModel.settings.robotsIndexAllow) { value in
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
        .navigationTitle(localizedString("privacy.title"))
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                ProgressView(localizedString("privacy.loading"))
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .task {
            await viewModel.load()
        }
        .alert(localizedString("common.notice"), isPresented: Binding(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.successMessage = nil } }
        )) {
            Button(localizedString("common.understood"), role: .cancel) {}
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
