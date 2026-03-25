import SwiftUI

struct FeedbackView: View {
    @StateObject private var viewModel: FeedbackViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: FeedbackViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DSCard {
                    Picker(localizedString("feedback.type"), selection: $viewModel.selectedType) {
                        ForEach(viewModel.typeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizedString("feedback.content"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DSColor.subtitle)
                        TextEditor(text: $viewModel.content)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    DSInputField(title: localizedString("feedback.contact"), placeholder: localizedString("feedback.contactPlaceholder"), text: $viewModel.contact)

                    if case .failure(let message) = viewModel.submitState {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(DSColor.danger)
                    }
                }

                DSButton(
                    title: localizedString("feedback.submit"),
                    icon: "paperplane",
                    isLoading: viewModel.submitState.isSubmitting,
                    isDisabled: !viewModel.isFormValid
                ) {
                    Task { await viewModel.submit() }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
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
