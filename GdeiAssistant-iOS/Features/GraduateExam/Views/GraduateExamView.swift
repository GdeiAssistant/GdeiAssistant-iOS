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
                TextField(localizedString("graduateExam.name"), text: $viewModel.query.name)
                TextField(localizedString("graduateExam.examNumber"), text: $viewModel.query.examNumber)
                TextField(localizedString("graduateExam.idNumber"), text: $viewModel.query.idNumber)
                Button(localizedString("graduateExam.query")) {
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
                Text(localizedString("graduateExam.queryInfo"))
            }

            if viewModel.isLoading {
                Section {
                    DSLoadingView(text: localizedString("graduateExam.querying"))
                }
            } else if let score = viewModel.score {
                Section {
                    Text("\(localizedString("graduateExam.totalScore"))\(score.totalScore)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DSColor.primary)
                    infoRow(localizedString("graduateExam.name"), score.name)
                    infoRow(localizedString("graduateExam.regNumber"), score.signupNumber)
                    infoRow(localizedString("graduateExam.examNumber"), score.examNumber)
                    infoRow(localizedString("graduateExam.politics"), score.politicsScore)
                    infoRow(localizedString("graduateExam.foreignLang"), score.foreignLanguageScore)
                    infoRow(localizedString("graduateExam.course1"), score.businessOneScore)
                    infoRow(localizedString("graduateExam.course2"), score.businessTwoScore)
                } header: {
                    Text(localizedString("graduateExam.result"))
                }
            }

            Section {
                Button(localizedString("graduateExam.openAltEntry")) {
                    if let url = URL(string: "https://yz.chsi.com.cn/apply/cjcxa/") {
                        openURL(url)
                    }
                }
            } header: {
                Text(localizedString("graduateExam.altEntry"))
            }
        }
        .navigationTitle(localizedString("graduateExam.title"))
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
