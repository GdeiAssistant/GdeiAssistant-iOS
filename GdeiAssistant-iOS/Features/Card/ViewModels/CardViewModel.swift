import Foundation
import Combine

@MainActor
final class CardViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var dashboard: CampusCardDashboard?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var submitState: SubmitState = .idle

    private let repository: any CardRepository

    init(repository: any CardRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard dashboard == nil else { return }
        await loadDashboard()
    }

    var selectedDateText: String {
        Self.dateFormatter.string(from: selectedDate)
    }

    func loadDashboard(for date: Date? = nil) async {
        let targetDate = date ?? selectedDate
        selectedDate = targetDate
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            dashboard = try await repository.fetchDashboard(on: targetDate)
        } catch {
            dashboard = nil
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "校园卡数据加载失败"
        }
    }

    func reportLoss(cardPassword: String) async {
        submitState = .submitting
        errorMessage = nil

        do {
            let request = CardLossRequest(cardPassword: cardPassword)
            try await repository.reportLoss(request: request)
            submitState = .success("校园卡已挂失，请尽快前往服务中心处理")
            await loadDashboard()
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "挂失失败，请稍后重试")
        }
    }

    func clearSubmitState() {
        submitState = .idle
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
