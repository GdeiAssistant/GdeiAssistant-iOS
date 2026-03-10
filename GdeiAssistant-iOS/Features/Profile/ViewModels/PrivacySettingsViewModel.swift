import Foundation
import Combine

@MainActor
final class PrivacySettingsViewModel: ObservableObject {
    @Published var settings = PrivacySettings.default
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let repository: any AccountCenterRepository

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            settings = try await repository.fetchPrivacySettings()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "加载隐私设置失败"
        }
    }

    func update(_ mutation: (inout PrivacySettings) -> Void) async {
        var next = settings
        mutation(&next)
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            settings = try await repository.updatePrivacySettings(next)
            successMessage = "隐私设置已更新"
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "保存隐私设置失败"
        }
    }
}
