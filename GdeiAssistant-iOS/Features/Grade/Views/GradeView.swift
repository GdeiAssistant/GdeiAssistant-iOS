import SwiftUI

struct GradeView: View {
    @StateObject private var viewModel: GradeViewModel

    init(viewModel: GradeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.report == nil {
                DSLoadingView(text: "正在加载成绩...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.report == nil {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.loadIfNeeded() }
                }
            } else if let report = viewModel.report {
                content(report)
            } else {
                DSEmptyStateView(icon: "chart.bar", title: "暂无成绩数据", message: "请稍后重试")
            }
        }
        .navigationTitle("我的成绩单")
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private func content(_ report: GradeReport) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                DSCard {
                    Text("学年")
                        .font(.subheadline)
                        .foregroundStyle(DSColor.subtitle)

                    Picker("学年", selection: yearBinding) {
                        ForEach(viewModel.displayYearOptions) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                DSCard {
                    Text("学期")
                        .font(.headline)
                        .foregroundStyle(DSColor.title)

                    Picker("学期", selection: $viewModel.selectedTermID) {
                        ForEach(report.terms) { term in
                            Text(term.title).tag(term.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let term = viewModel.selectedTermReport {
                    DSCard {
                        Text(term.title)
                            .font(.headline)
                            .foregroundStyle(DSColor.title)

                        HStack {
                            summaryItem(title: "绩点", value: String(format: "%.2f", term.gpa))
                            summaryItem(title: "课程数", value: "\(term.items.count)")
                        }

                        if term.items.isEmpty {
                            Text("当前学期暂无成绩")
                                .font(.subheadline)
                                .foregroundStyle(DSColor.subtitle)
                        } else {
                            ForEach(term.items) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.courseName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(DSColor.title)
                                        Spacer()
                                        Text(String(format: "%.1f", item.score))
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(DSColor.primary)
                                    }

                                    Text("\(item.courseType) · \(item.credit, specifier: "%.1f") 学分")
                                        .font(.caption)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.background)
        .refreshable {
            await viewModel.loadGrades(academicYear: report.selectedYear)
        }
    }

    private var yearBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedYear },
            set: { newValue in
                Task { await viewModel.changeYear(newValue) }
            }
        )
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DSColor.subtitle)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(DSColor.title)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        GradeView(viewModel: GradeViewModel(repository: MockGradeRepository()))
    }
}
