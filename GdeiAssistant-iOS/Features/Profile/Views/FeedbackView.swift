import SwiftUI

struct FeedbackView: View {
    @StateObject private var viewModel: FeedbackViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: FeedbackViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                Picker(localizedString("feedback.type"), selection: $viewModel.selectedType) {
                    ForEach(viewModel.typeOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                TextEditor(text: $viewModel.content)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
            } header: {
                Text(localizedString("feedback.content"))
            }

            Section {
                DSInputField(title: localizedString("feedback.contact"), placeholder: localizedString("feedback.contactPlaceholder"), text: $viewModel.contact)
            } header: {
                Text(localizedString("feedback.contact"))
            } footer: {
                if case .failure(let message) = viewModel.submitState {
                    Text(message)
                        .foregroundStyle(DSColor.danger)
                }
            }

            Section {
                DSButton(
                    title: localizedString("feedback.submit"),
                    icon: "paperplane",
                    isLoading: viewModel.submitState.isSubmitting,
                    isDisabled: !viewModel.isFormValid
                ) {
                    Task { await viewModel.submit() }
                }
                .dsActionRow()
            }
        }
        .dsForm()
        .navigationTitle(localizedString("feedback.title"))
        .alert(localizedString("common.notice"), isPresented: Binding(
            get: {
                if case .success = viewModel.submitState { return true }
                return false
            },
            set: { if !$0 { viewModel.submitState = .idle } }
        )) {
            Button(localizedString("feedback.done")) {
                viewModel.submitState = .idle
                dismiss()
            }
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
    }
}
