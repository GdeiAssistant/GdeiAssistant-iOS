import Foundation
import Combine

@MainActor
final class GradeViewModel: ObservableObject {
    struct DisplayYearOption: Identifiable, Hashable {
        let id: String
        let title: String
    }

    @Published var selectedYear: String = ""
    @Published var selectedTermID: String = "1"
    @Published var yearOptions: [AcademicYearOption] = []
    @Published var report: GradeReport?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any GradeRepository

    init(repository: any GradeRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        if report == nil {
            await loadGrades(academicYear: selectedYear.isEmpty ? "2025-2026" : selectedYear)
        }
    }

    func changeYear(_ year: String) async {
        guard selectedYear != year else { return }
        await loadGrades(academicYear: year)
    }

    func loadGrades(academicYear: String) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let fetched = try await repository.fetchGrades(academicYear: academicYear)
            report = fetched
            yearOptions = fetched.yearOptions
            selectedYear = fetched.selectedYear
            let preferredTerm = fetched.terms.first(where: { $0.id == selectedTermID && !$0.items.isEmpty })?.id
            selectedTermID = preferredTerm ?? fetched.terms.first(where: { !$0.items.isEmpty })?.id ?? "1"
        } catch {
            report = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("grade.loadFailed")
        }
    }

    var selectedTermReport: GradeTermReport? {
        report?.terms.first(where: { $0.id == selectedTermID }) ?? report?.terms.first
    }

    var displayYearOptions: [DisplayYearOption] {
        let labels = [localizedString("grade.year.freshman"), localizedString("grade.year.sophomore"), localizedString("grade.year.junior"), localizedString("grade.year.senior")]
        return yearOptions.enumerated().map { index, option in
            let title = index < labels.count ? labels[index] : option.title
            return DisplayYearOption(id: option.id, title: title)
        }
    }
}
