import SwiftUI

struct GraduateExamView: View {
    @StateObject private var viewModel: GraduateExamViewModel
    @Environment(\.openURL) private var openURL

    init(viewModel: GraduateExamViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                TextField("姓名", text: $viewModel.query.name)
                TextField("准考证号", text: $viewModel.query.examNumber)
                TextField("证件号码", text: $viewModel.query.idNumber)
                Button("查询成绩") {
                    Task { await viewModel.submit() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(DSColor.danger)
                }
            } header: {
                Text("查询信息")
            }

            if viewModel.isLoading {
                Section {
                    DSLoadingView(text: "正在查询考研成绩...")
                }
            } else if let score = viewModel.score {
                Section {
                    Text("总分：\(score.totalScore)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DSColor.primary)
                    infoRow("姓名", score.name)
                    infoRow("报名号", score.signupNumber)
                    infoRow("准考证号", score.examNumber)
                    infoRow("思想政治理论", score.politicsScore)
                    infoRow("外国语", score.foreignLanguageScore)
                    infoRow("业务课一", score.businessOneScore)
                    infoRow("业务课二", score.businessTwoScore)
                } header: {
                    Text("查询结果")
                }
            }

            Section {
                Button("打开研招网备用入口") {
                    if let url = URL(string: "https://yz.chsi.com.cn/apply/cjcxa/") {
                        openURL(url)
                    }
                }
            } header: {
                Text("备用入口")
            }
        }
        .navigationTitle("考研查询")
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(DSColor.subtitle)
        }
    }
}

#Preview {
    NavigationStack {
        GraduateExamView(viewModel: GraduateExamViewModel(repository: MockGraduateExamRepository()))
    }
}
