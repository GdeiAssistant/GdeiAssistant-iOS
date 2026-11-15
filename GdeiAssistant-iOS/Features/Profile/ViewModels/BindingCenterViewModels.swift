import Foundation
import Combine

private final class CountdownTaskBox: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, Never>?

    func replace(_ newTask: Task<Void, Never>?) {
        lock.withLock {
            task?.cancel()
            task = newTask
        }
    }

    func cancel() {
        lock.withLock {
            task?.cancel()
            task = nil
        }
    }
}

@MainActor
final class BindPhoneViewModel: ObservableObject {
    @Published var attributions: [PhoneAttribution] = []
    @Published var selectedAreaCode = 86
    @Published var phone = ""
    @Published var randomCode = ""
    @Published var status = ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: localizedString("bindPhone.notBound"), note: localizedString("bindPhone.notBoundHint"), countryCode: nil, username: nil)
    @Published var isLoading = false
    @Published var isSendingCode = false
    @Published var countdown = 0
    @Published var submitState: SubmitState = .idle

    private let repository: any AccountCenterRepository
    private let countdownTaskBox = CountdownTaskBox()

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    // Cancel without isolating deinit to MainActor (swiftlang/swift#87316).
    nonisolated deinit {
        countdownTaskBox.cancel()
    }

    var canSendCode: Bool {
        countdown == 0 && !isSendingCode
    }

    var selectedAttribution: PhoneAttribution? {
        attributions.first(where: { $0.code == selectedAreaCode })
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let bundledAttributions = PhoneAttributionCatalog.load()
        async let remoteAttributionTask = repository.fetchPhoneAttributions()
        async let statusTask = repository.fetchPhoneStatus()

        do {
            status = try await statusTask
            let remoteAttributions = (try? await remoteAttributionTask) ?? []
            let mergedAttributions = PhoneAttributionCatalog.mergeAndSort(
                primary: bundledAttributions,
                overlay: remoteAttributions
            )
            attributions = mergedAttributions.isEmpty ? remoteAttributions : mergedAttributions
            selectedAreaCode =
                status.countryCode
                ?? attributions.first(where: { $0.code == 86 })?.code
                ?? attributions.first?.code
                ?? 86
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("bindPhone.loadFailed"))
        }
    }

    func sendCode() async {
        let normalizedPhone = FormValidationSupport.digitsOnly(phone, maxLength: 11)
        phone = normalizedPhone
        guard normalizedPhone.count >= 7 else {
            submitState = .failure(localizedString("bindPhone.invalidFormat"))
            return
        }
        isSendingCode = true
        defer { isSendingCode = false }
        do {
            try await repository.sendPhoneVerification(areaCode: selectedAreaCode, phone: normalizedPhone)
            startCountdown()
            submitState = .success(localizedString("bindPhone.codeSent"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("bindPhone.codeFailed"))
        }
    }

    func bind() async {
        let normalizedPhone = FormValidationSupport.digitsOnly(phone, maxLength: 11)
        phone = normalizedPhone
        guard normalizedPhone.count >= 7, FormValidationSupport.hasText(randomCode) else {
            submitState = .failure(localizedString("bindPhone.formEmpty"))
            return
        }
        submitState = .submitting
        do {
            status = try await repository.bindPhone(
                request: PhoneBindRequest(
                    areaCode: selectedAreaCode,
                    phone: normalizedPhone,
                    randomCode: FormValidationSupport.trimmed(randomCode)
                )
            )
            submitState = .success(localizedString("bindPhone.bindSuccess"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("bindPhone.bindFailed"))
        }
    }

    func unbind() async {
        submitState = .submitting
        do {
            status = try await repository.unbindPhone()
            submitState = .success(localizedString("bindPhone.unbindSuccess"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("bindPhone.unbindFailed"))
        }
    }

    private func startCountdown() {
        countdown = 60
        let task = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.countdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                if self.countdown > 0 {
                    self.countdown -= 1
                }
            }
        }
        countdownTaskBox.replace(task)
    }
}

@MainActor
final class BindEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var randomCode = ""
    @Published var status = ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: localizedString("bindEmail.notBound"), note: localizedString("bindEmail.notBoundHint"), countryCode: nil, username: nil)
    @Published var isLoading = false
    @Published var isSendingCode = false
    @Published var countdown = 0
    @Published var submitState: SubmitState = .idle

    private let repository: any AccountCenterRepository
    private let countdownTaskBox = CountdownTaskBox()

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    // Cancel without isolating deinit to MainActor (swiftlang/swift#87316).
    nonisolated deinit {
        countdownTaskBox.cancel()
    }

    var canSendCode: Bool {
        countdown == 0 && !isSendingCode
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            status = try await repository.fetchEmailStatus()
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("bindEmail.loadFailed"))
        }
    }

    func sendCode() async {
        let normalizedEmail = FormValidationSupport.trimmed(email)
        email = normalizedEmail
        guard normalizedEmail.contains("@"), normalizedEmail.contains("."),
              let atIndex = normalizedEmail.firstIndex(of: "@"),
              normalizedEmail[normalizedEmail.startIndex..<atIndex].count >= 1,
              normalizedEmail[normalizedEmail.index(after: atIndex)...].contains(".") else {
            submitState = .failure(localizedString("bindEmail.invalidFormat"))
            return
        }
        isSendingCode = true
        defer { isSendingCode = false }
        do {
            try await repository.sendEmailVerification(email: normalizedEmail)
            startCountdown()
            submitState = .success(localizedString("bindEmail.codeSent"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("bindEmail.codeFailed"))
        }
    }

    func bind() async {
        let normalizedEmail = FormValidationSupport.trimmed(email)
        email = normalizedEmail
        guard normalizedEmail.contains("@"), normalizedEmail.contains("."),
              normalizedEmail.firstIndex(of: "@").map({ normalizedEmail[$0...].contains(".") }) == true,
              FormValidationSupport.hasText(randomCode) else {
            submitState = .failure(localizedString("bindEmail.formEmpty"))
            return
        }
        submitState = .submitting
        do {
            status = try await repository.bindEmail(
                email: normalizedEmail,
                randomCode: FormValidationSupport.trimmed(randomCode)
            )
            submitState = .success(localizedString("bindEmail.bindSuccess"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("bindEmail.bindFailed"))
        }
    }

    func unbind() async {
        submitState = .submitting
        do {
            status = try await repository.unbindEmail()
            submitState = .success(localizedString("bindEmail.unbindSuccess"))
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? localizedString("bindEmail.unbindFailed"))
        }
    }

    private func startCountdown() {
        countdown = 60
        let task = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.countdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                if self.countdown > 0 {
                    self.countdown -= 1
                }
            }
        }
        countdownTaskBox.replace(task)
    }
}
