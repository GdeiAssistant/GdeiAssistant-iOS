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
                    .keyboardType(.asciiCapable)
                TextField(localizedString("graduateExam.idNumber"), text: $viewModel.query.idNumber)
                    .keyboardType(.asciiCapable)
            } header: {
                Text(localizedString("graduateExam.queryInfo"))
            } footer: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(DSColor.danger)
                }
            }

            Section {
                DSButton(
                    title: localizedString("graduateExam.query"),
                    icon: "magnifyingglass",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.isLoading
                ) {
                    Task { await viewModel.submit() }
                }
                .dsActionRow()
            }

            if viewModel.isLoading {
                Section {
                    DSLoadingView(text: localizedString("graduateExam.querying"))
                }
            } else if let score = viewModel.score {
                Section {
                    VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                        Text(localizedString("graduateExam.totalScore"))
                            .font(.subheadline)
                            .foregroundStyle(DSColor.subtitle)
                        Text(score.totalScore)
                            .font(.largeTitle.weight(.bold).monospacedDigit())
                            .foregroundStyle(DSColor.primary)
                    }
                    .padding(.vertical, DSSpacing.xxs)
                    .accessibilityElement(children: .combine)
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
                Button {
                    if let url = URL(string: "https://yz.chsi.com.cn/apply/cjcxa/") {
                        openURL(url)
                    }
                } label: {
                    Label(localizedString("graduateExam.openAltEntry"), systemImage: "arrow.up.right.square")
                }
            } header: {
                Text(localizedString("graduateExam.altEntry"))
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(localizedString("graduateExam.title"))
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        LabeledContent(title) {
            Text(value)
                .monospacedDigit()
        }
    }
}

#Preview {
    NavigationStack {
        GraduateExamView(viewModel: GraduateExamViewModel(repository: MockGraduateExamRepository()))
    }
}
