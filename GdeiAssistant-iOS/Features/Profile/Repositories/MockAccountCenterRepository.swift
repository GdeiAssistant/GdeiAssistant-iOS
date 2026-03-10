import Foundation

@MainActor
final class MockAccountCenterRepository: AccountCenterRepository {
    private var privacySettings = PrivacySettings.default
    private var phoneStatus = ContactBindingStatus(isBound: true, rawValue: "13812345678", maskedValue: "138****5678", note: "已绑定常用手机号（+86）", countryCode: 86, username: MockSeedData.demoProfile.username)
    private var emailStatus = ContactBindingStatus(isBound: true, rawValue: "student@gdei.edu.cn", maskedValue: "stu***@gdei.edu.cn", note: "已绑定邮箱，可接收验证码与服务通知", countryCode: nil, username: nil)
    private var downloadState = DownloadDataStatus(state: .idle, message: "你可以随时导出个人数据副本。", downloadURL: nil)
    private var avatarState = AvatarState(url: MockFactory.makeUserProfile().avatarURL)
    private var records: [LoginRecordItem] = [
        LoginRecordItem(id: "1", timeText: "2026-03-08 09:24", ip: "113.108.18.12", area: "广东 广州", device: "iPhone 15 Pro", statusText: "登录成功"),
        LoginRecordItem(id: "2", timeText: "2026-03-07 21:16", ip: "113.108.18.15", area: "广东 广州", device: "Web", statusText: "登录成功"),
        LoginRecordItem(id: "3", timeText: "2026-03-05 08:02", ip: "120.230.17.88", area: "广东 佛山", device: "iPad", statusText: "登录成功")
    ]

    func fetchPrivacySettings() async throws -> PrivacySettings {
        try await Task.sleep(nanoseconds: 150_000_000)
        return privacySettings
    }

    func updatePrivacySettings(_ settings: PrivacySettings) async throws -> PrivacySettings {
        try await Task.sleep(nanoseconds: 180_000_000)
        privacySettings = settings
        return settings
    }

    func fetchLoginRecords() async throws -> [LoginRecordItem] {
        try await Task.sleep(nanoseconds: 150_000_000)
        return records
    }

    func fetchPhoneAttributions() async throws -> [PhoneAttribution] {
        [
            PhoneAttribution(id: 86, code: 86, flag: "🇨🇳", name: "中国大陆"),
            PhoneAttribution(id: 852, code: 852, flag: "🇭🇰", name: "中国香港"),
            PhoneAttribution(id: 853, code: 853, flag: "🇲🇴", name: "中国澳门")
        ]
    }

    func fetchPhoneStatus() async throws -> ContactBindingStatus {
        phoneStatus
    }

    func sendPhoneVerification(areaCode: Int, phone: String) async throws {
        try await Task.sleep(nanoseconds: 120_000_000)
        guard phone.count >= 7 else {
            throw NetworkError.server(code: 400, message: "手机号长度不正确")
        }
        _ = areaCode
    }

    func bindPhone(request: PhoneBindRequest) async throws -> ContactBindingStatus {
        try await Task.sleep(nanoseconds: 180_000_000)
        guard request.randomCode == "123456" else {
            throw NetworkError.server(code: 400, message: "验证码不正确")
        }
        phoneStatus = ContactBindingStatus(
            isBound: true,
            rawValue: request.phone,
            maskedValue: "\(request.phone.prefix(3))****\(request.phone.suffix(4))",
            note: "已绑定常用手机号（+\(request.areaCode)）",
            countryCode: request.areaCode,
            username: MockSeedData.demoProfile.username
        )
        return phoneStatus
    }

    func unbindPhone() async throws -> ContactBindingStatus {
        try await Task.sleep(nanoseconds: 150_000_000)
        phoneStatus = ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: "未绑定", note: "尚未绑定手机号", countryCode: nil, username: nil)
        return phoneStatus
    }

    func fetchEmailStatus() async throws -> ContactBindingStatus {
        emailStatus
    }

    func sendEmailVerification(email: String) async throws {
        try await Task.sleep(nanoseconds: 120_000_000)
        guard email.contains("@") else {
            throw NetworkError.server(code: 400, message: "邮箱格式不正确")
        }
    }

    func bindEmail(email: String, randomCode: String) async throws -> ContactBindingStatus {
        try await Task.sleep(nanoseconds: 180_000_000)
        guard randomCode == "123456" else {
            throw NetworkError.server(code: 400, message: "验证码不正确")
        }
        let masked = AccountCenterRemoteMapper.mapEmailStatus(email).maskedValue
        emailStatus = ContactBindingStatus(isBound: true, rawValue: email, maskedValue: masked, note: "已绑定邮箱，可接收验证码与通知", countryCode: nil, username: nil)
        return emailStatus
    }

    func unbindEmail() async throws -> ContactBindingStatus {
        try await Task.sleep(nanoseconds: 150_000_000)
        emailStatus = ContactBindingStatus(isBound: false, rawValue: nil, maskedValue: "未绑定", note: "尚未绑定邮箱", countryCode: nil, username: nil)
        return emailStatus
    }

    func submitFeedback(_ submission: FeedbackSubmission) async throws {
        try await Task.sleep(nanoseconds: 220_000_000)
        guard FormValidationSupport.hasText(submission.content) else {
            throw NetworkError.server(code: 400, message: "反馈内容不能为空")
        }
    }

    func fetchDownloadStatus() async throws -> DownloadDataStatus {
        downloadState
    }

    func startDataExport() async throws -> DownloadDataStatus {
        try await Task.sleep(nanoseconds: 250_000_000)
        downloadState = DownloadDataStatus(state: .exporting, message: "系统正在导出你的数据，请稍后查看。", downloadURL: nil)
        return downloadState
    }

    func fetchDownloadURL() async throws -> DownloadDataStatus {
        try await Task.sleep(nanoseconds: 200_000_000)
        downloadState = DownloadDataStatus(state: .exported, message: "数据已打包完成，可立即下载。", downloadURL: "https://mock.gdeiassistant.cn/export/userdata-demo.zip")
        return downloadState
    }

    func fetchAvatarState() async throws -> AvatarState {
        avatarState
    }

    func uploadAvatar(_ avatar: UploadImageAsset) async throws -> AvatarState {
        try await Task.sleep(nanoseconds: 220_000_000)
        _ = avatar
        avatarState = AvatarState(url: "https://mock.gdeiassistant.cn/avatar/demo.jpg")
        return avatarState
    }

    func deleteAvatar() async throws -> AvatarState {
        try await Task.sleep(nanoseconds: 180_000_000)
        avatarState = AvatarState(url: nil)
        return avatarState
    }

    func deleteAccount(password: String) async throws {
        try await Task.sleep(nanoseconds: 250_000_000)
        guard password == "123456" else {
            throw NetworkError.server(code: 400, message: "密码校验失败，无法注销账号")
        }
    }
}
