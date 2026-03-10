import SwiftUI

struct EvaluateView: View {
    @StateObject private var viewModel: EvaluateViewModel

    init(viewModel: EvaluateViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Toggle("直接提交评教信息", isOn: $viewModel.submission.directSubmit)
                Text("注意：评教信息提交后将不能再次修改，请确认当前学期评教已准备完成。")
                    .font(.footnote)
                    .foregroundStyle(DSColor.subtitle)
            } header: {
                Text("教学评价")
            }

            Section {
                Button {
                    viewModel.requestSubmit()
                } label: {
                    if viewModel.submitState.isSubmitting {
                        HStack {
                            ProgressView()
                            Text("正在提交")
                        }
                    } else {
                        Text("一键评教")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(viewModel.submitState.isSubmitting)
            }
        }
        .navigationTitle("教学评价")
        .confirmationDialog("确认提交评教？", isPresented: $viewModel.showConfirm, titleVisibility: .visible) {
            Button("确认提交", role: .destructive) {
                Task { await viewModel.submit() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("该操作不可逆，请确认后再继续。")
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.submitState.message != nil },
            set: { if !$0 { viewModel.submitState = .idle } }
        )) {
            Button("知道了", role: .cancel) {}
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
