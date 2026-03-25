import Foundation
import Combine

@MainActor
final class ElectricityFeesViewModel: ObservableObject {
    @Published var query = ElectricityQuery()
    @Published var bill: ElectricityBill?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any DataCenterRepository

    init(repository: any DataCenterRepository) {
        self.repository = repository
    }

    var availableYears: [Int] {
        ElectricityQuery.yearOptions
    }

    func submit() async {
        guard FormValidationSupport.hasText(query.name), FormValidationSupport.hasText(query.studentNumber) else {
            errorMessage = localizedString("dataCenter.nameOrIDEmpty")
            bill = nil
            return
        }
        let trimmedNumber = FormValidationSupport.trimmed(query.studentNumber)
        if FormValidationSupport.digitsOnly(trimmedNumber, maxLength: 11) != trimmedNumber || trimmedNumber.count != 11 {
            errorMessage = localizedString("dataCenter.invalidStudentID")
            bill = nil
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            bill = try await repository.queryElectricity(query)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("dataCenter.electricFailed")
        }
    }
}

@MainActor
final class YellowPageViewModel: ObservableObject {
    @Published var categories: [YellowPageCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any DataCenterRepository

    init(repository: any DataCenterRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard categories.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            categories = try await repository.fetchYellowPages()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("dataCenter.yellowPageFailed")
        }
    }
}
