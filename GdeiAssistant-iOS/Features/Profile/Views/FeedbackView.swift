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
                    Picker("反馈类型", selection: $viewModel.selectedType) {
                        ForEach(viewModel.typeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("反馈内容")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DSColor.subtitle)
                        TextEditor(text: $viewModel.content)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    DSInputField(title: "联系方式", placeholder: "邮箱 / 手机号（选填）", text: $viewModel.contact)

                    if case .failure(let message) = viewModel.submitState {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(DSColor.danger)
                    }
                }

                DSButton(
                    title: "提交反馈",
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
        .navigationTitle("帮助与反馈")
        .alert("提示", isPresented: Binding(
            get: {
                if case .success = viewModel.submitState { return true }
                return false
            },
            set: { if !$0 { viewModel.submitState = .idle } }
        )) {
            Button("完成") {
                viewModel.submitState = .idle
                dismiss()
            }
        } message: {
            Text(viewModel.submitState.message ?? "")
        }
    }
}
