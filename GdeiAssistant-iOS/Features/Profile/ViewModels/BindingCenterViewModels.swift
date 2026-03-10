import Foundation
import Combine

@MainActor
final class BindPhoneViewModel: ObservableObject {
    @Published var attributions: [PhoneAttribution] = []
    @Published var selectedAreaCode = 86
    @Published var phone = ""
    @Published var randomCode = ""
    @Published var status = ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: "未绑定", note: "尚未绑定手机号", countryCode: nil, username: nil)
    @Published var isLoading = false
    @Published var isSendingCode = false
    @Published var countdown = 0
    @Published var submitState: SubmitState = .idle

    private let repository: any AccountCenterRepository
    private var countdownTask: Task<Void, Never>?

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    deinit {
        countdownTask?.cancel()
    }

    var canSendCode: Bool {
        countdown == 0 && !isSendingCode
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let attributionTask = repository.fetchPhoneAttributions()
            async let statusTask = repository.fetchPhoneStatus()
            attributions = try await attributionTask
            status = try await statusTask
            selectedAreaCode = status.countryCode ?? attributions.first?.code ?? 86
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "加载手机号信息失败")
        }
    }

    func sendCode() async {
        let normalizedPhone = FormValidationSupport.digitsOnly(phone, maxLength: 11)
        phone = normalizedPhone
        guard normalizedPhone.count >= 7 else {
            submitState = .failure("请输入正确的手机号")
            return
        }
        isSendingCode = true
        defer { isSendingCode = false }
        do {
            try await repository.sendPhoneVerification(areaCode: selectedAreaCode, phone: normalizedPhone)
            startCountdown()
            submitState = .success("验证码已发送，请查收短信")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "发送验证码失败")
        }
    }

    func bind() async {
        let normalizedPhone = FormValidationSupport.digitsOnly(phone, maxLength: 11)
        phone = normalizedPhone
        guard normalizedPhone.count >= 7, FormValidationSupport.hasText(randomCode) else {
            submitState = .failure("请填写手机号和验证码")
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
            submitState = .success("手机号绑定成功")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "手机号绑定失败")
        }
    }

    func unbind() async {
        submitState = .submitting
        do {
            status = try await repository.unbindPhone()
            submitState = .success("手机号已解绑")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "手机号解绑失败")
        }
    }

    private func startCountdown() {
        countdown = 60
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.countdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                if self.countdown > 0 {
                    self.countdown -= 1
                }
            }
        }
    }
}

@MainActor
final class BindEmailViewModel: ObservableObject {
    @Published var email = ""
    @Published var randomCode = ""
    @Published var status = ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: "未绑定", note: "尚未绑定邮箱", countryCode: nil, username: nil)
    @Published var isLoading = false
    @Published var isSendingCode = false
    @Published var countdown = 0
    @Published var submitState: SubmitState = .idle

    private let repository: any AccountCenterRepository
    private var countdownTask: Task<Void, Never>?

    init(repository: any AccountCenterRepository) {
        self.repository = repository
    }

    deinit {
        countdownTask?.cancel()
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
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "加载邮箱状态失败")
        }
    }

    func sendCode() async {
        let normalizedEmail = FormValidationSupport.trimmed(email)
        email = normalizedEmail
        guard normalizedEmail.contains("@") else {
            submitState = .failure("请输入正确的邮箱地址")
            return
        }
        isSendingCode = true
        defer { isSendingCode = false }
        do {
            try await repository.sendEmailVerification(email: normalizedEmail)
            startCountdown()
            submitState = .success("验证码已发送，请查收邮件")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "发送验证码失败")
        }
    }

    func bind() async {
        let normalizedEmail = FormValidationSupport.trimmed(email)
        email = normalizedEmail
        guard normalizedEmail.contains("@"), FormValidationSupport.hasText(randomCode) else {
            submitState = .failure("请填写邮箱和验证码")
            return
        }
        submitState = .submitting
        do {
            status = try await repository.bindEmail(
                email: normalizedEmail,
                randomCode: FormValidationSupport.trimmed(randomCode)
            )
            submitState = .success("邮箱绑定成功")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "邮箱绑定失败")
        }
    }

    func unbind() async {
        submitState = .submitting
        do {
            status = try await repository.unbindEmail()
            submitState = .success("邮箱已解绑")
        } catch {
            submitState = .failure((error as? LocalizedError)?.errorDescription ?? "邮箱解绑失败")
        }
    }

    private func startCountdown() {
        countdown = 60
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.countdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                if self.countdown > 0 {
                    self.countdown -= 1
                }
            }
        }
    }
}
