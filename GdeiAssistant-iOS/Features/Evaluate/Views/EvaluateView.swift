import SwiftUI

struct EvaluateView: View {
    @StateObject private var viewModel: EvaluateViewModel

    init(viewModel: EvaluateViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Toggle(localizedString("evaluate.description"), isOn: $viewModel.submission.directSubmit)
                    .tint(DSColor.primary)
            } header: {
                Text(localizedString("evaluate.title"))
            } footer: {
                Label(localizedString("evaluate.warning"), systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(DSColor.warning)
            }

            Section {
                DSButton(
                    title: viewModel.submitState.isSubmitting
                        ? localizedString("evaluate.submitting")
                        : localizedString("evaluate.oneClick"),
                    icon: "checkmark.seal",
                    isLoading: viewModel.submitState.isSubmitting,
                    isDisabled: viewModel.submitState.isSubmitting
                ) {
                    viewModel.requestSubmit()
                }
                .dsActionRow()
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
        .navigationTitle(localizedString("evaluate.title"))
        .confirmationDialog(localizedString("evaluate.confirmTitle"), isPresented: $viewModel.showConfirm, titleVisibility: .visible) {
            Button(localizedString("evaluate.confirmSubmit"), role: .destructive) {
                Task { await viewModel.submit() }
            }
            Button(localizedString("common.cancel"), role: .cancel) {}
        } message: {
            Text(localizedString("evaluate.irreversible"))
        }
        .alert(localizedString("evaluate.notice"), isPresented: Binding(
            get: { viewModel.submitState.message != nil },
            set: { if !$0 { viewModel.submitState = .idle } }
        )) {
            Button(localizedString("evaluate.understood"), role: .cancel) {}
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        EvaluateView(viewModel: EvaluateViewModel(repository: MockEvaluateRepository()))
    }
}
