import SwiftUI

struct GradeView: View {
    @StateObject private var viewModel: GradeViewModel

    init(viewModel: GradeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.report == nil {
                DSLoadingView(text: localizedString("grade.loading"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.report == nil {
                DSErrorStateView(message: errorMessage) {
                    Task { await viewModel.loadIfNeeded() }
                }
            } else if let report = viewModel.report {
                content(report)
            } else {
                DSEmptyStateView(icon: "chart.bar", title: localizedString("grade.emptyTitle"), message: localizedString("grade.emptyMsg"))
            }
        }
        .navigationTitle(localizedString("grade.title"))
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private func content(_ report: GradeReport) -> some View {
        List {
            Section {
                Picker(localizedString("grade.academicYear"), selection: yearBinding) {
                    ForEach(viewModel.displayYearOptions) { option in
                        Text(option.title).tag(option.id)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("grade.yearPicker")

                Picker(localizedString("grade.semester"), selection: $viewModel.selectedTermID) {
                    ForEach(report.terms) { term in
                        Text(term.title).tag(term.id)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("grade.termPicker")
            } header: {
                Text(localizedString("grade.academicYear"))
            }

            if let term = viewModel.selectedTermReport {
                Section {
                    LabeledContent(localizedString("grade.gpa")) {
                        Text(String(format: "%.2f", term.gpa))
                            .font(.body.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(DSColor.primary)
                    }
                    LabeledContent(localizedString("grade.courseCount")) {
                        Text("\(term.items.count)")
                            .monospacedDigit()
                            .foregroundStyle(DSColor.title)
                    }
                } header: {
                    Text(term.title)
                        .accessibilityIdentifier("grade.term.title")
                }

                Section {
                    if term.items.isEmpty {
                        Text(localizedString("grade.noGrade"))
                            .foregroundStyle(DSColor.subtitle)
                    } else {
                        ForEach(term.items) { item in
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.courseName)
                                        .foregroundStyle(DSColor.title)
                                        .accessibilityIdentifier("grade.course.\(item.id)")
                                    Text("\(item.courseType) · \(item.credit, specifier: "%.1f")\(localizedString("grade.credit"))")
                                        .font(.footnote)
                                        .foregroundStyle(DSColor.subtitle)
                                }
                                Spacer(minLength: DSSpacing.xs)
                                Text(String(format: "%.1f", item.score))
                                    .font(.body.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(item.score < 60 ? DSColor.danger : DSColor.title)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .dsListBackground()
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
}

#Preview {
    NavigationStack {
        GradeView(viewModel: GradeViewModel(repository: MockGradeRepository()))
    }
}
