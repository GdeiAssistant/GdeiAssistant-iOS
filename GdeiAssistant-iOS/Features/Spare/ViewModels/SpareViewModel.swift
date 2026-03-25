import Foundation
import Combine

@MainActor
final class SpareViewModel: ObservableObject {
    @Published var query = SpareQuery()
    @Published var items: [SpareRoomItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: any SpareRepository

    init(repository: any SpareRepository) {
        self.repository = repository
    }

    func submitQuery() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await repository.queryRooms(query)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? localizedString("spare.loadFailed")
            items = []
        }
    }
}
