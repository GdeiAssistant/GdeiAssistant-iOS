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
                Text(localizedString("evaluate.warning"))
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text(localizedString("evaluate.title"))
            }

            Section {
                Button {
                    viewModel.requestSubmit()
                } label: {
                    if viewModel.submitState.isSubmitting {
                        HStack {
                            ProgressView()
                            Text(localizedString("evaluate.submitting"))
                        }
                    } else {
                        Text(localizedString("evaluate.oneClick"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(viewModel.submitState.isSubmitting)
            }
        }
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
