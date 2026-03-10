import Foundation

enum AccountCenterRemoteMapper {
    nonisolated static func mapPrivacySettings(_ dto: PrivacySettingsDTO?) -> PrivacySettings {
        PrivacySettings(
            facultyOpen: dto?.facultyOpen ?? false,
            majorOpen: dto?.majorOpen ?? false,
            locationOpen: dto?.locationOpen ?? false,
            hometownOpen: dto?.hometownOpen ?? false,
            introductionOpen: dto?.introductionOpen ?? true,
            enrollmentOpen: dto?.enrollmentOpen ?? false,
            ageOpen: dto?.ageOpen ?? false,
            cacheAllow: dto?.cacheAllow ?? false,
            robotsIndexAllow: dto?.robotsIndexAllow ?? false
        )
    }

    nonisolated static func mapPrivacyDTO(_ settings: PrivacySettings) -> PrivacySettingsDTO {
        PrivacySettingsDTO(
            facultyOpen: settings.facultyOpen,
            majorOpen: settings.majorOpen,
            locationOpen: settings.locationOpen,
            hometownOpen: settings.hometownOpen,
            introductionOpen: settings.introductionOpen,
            enrollmentOpen: settings.enrollmentOpen,
            ageOpen: settings.ageOpen,
            cacheAllow: settings.cacheAllow,
            robotsIndexAllow: settings.robotsIndexAllow
        )
    }

    nonisolated static func mapPhoneAttributions(_ dtos: [PhoneAttributionDTO]) -> [PhoneAttribution] {
        dtos.compactMap { dto in
            guard let code = dto.code else { return nil }
            return PhoneAttribution(
                id: code,
                code: code,
                flag: dto.flag ?? "",
                name: RemoteMapperSupport.firstNonEmpty(dto.name, "未知地区")
            )
        }
    }

    nonisolated static func mapPhoneStatus(_ dto: PhoneStatusDTO?) -> ContactBindingStatus {
        let phone = dto?.phone?.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = dto?.code
        let note: String
        if phone == nil || phone?.isEmpty == true {
            note = "尚未绑定手机号"
        } else if let code {
            note = "已绑定手机号（+\(code)），可用于安全验证与通知提醒"
        } else {
            note = "已绑定手机号，可用于安全验证与通知提醒"
        }
        return ContactBindingStatus(
            isBound: !(phone?.isEmpty ?? true),
            rawValue: phone,
            maskedValue: maskPhone(phone),
            note: note,
            countryCode: code,
            username: RemoteMapperSupport.sanitizedText(dto?.username)
        )
    }

    nonisolated static func mapEmailStatus(_ value: String?) -> ContactBindingStatus {
        let email = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return ContactBindingStatus(
            isBound: !(email?.isEmpty ?? true),
            rawValue: email,
            maskedValue: maskEmail(email),
            note: email == nil || email?.isEmpty == true ? "尚未绑定邮箱" : "已绑定邮箱，可用于接收验证码与服务通知",
            countryCode: nil,
            username: nil
        )
    }

    nonisolated static func mapFeedbackDTO(_ submission: FeedbackSubmission) -> FeedbackSubmitRemoteDTO {
        FeedbackSubmitRemoteDTO(
            content: FormValidationSupport.trimmed(submission.content),
            contact: FormValidationSupport.hasText(submission.contact ?? "") ? FormValidationSupport.trimmed(submission.contact ?? "") : nil,
            type: FormValidationSupport.hasText(submission.type ?? "") ? FormValidationSupport.trimmed(submission.type ?? "") : nil
        )
    }

    nonisolated static func mapLoginRecords(_ dtos: [LoginRecordDTO]) -> [LoginRecordItem] {
        dtos.map { dto in
            let area = RemoteMapperSupport.firstNonEmpty(
                dto.area,
                [dto.country, dto.province, dto.city].compactMap { $0 }.joined(separator: " "),
                "未知地区"
            )
            return LoginRecordItem(
                id: String(dto.id ?? Int.random(in: 1...999_999)),
                timeText: RemoteMapperSupport.dateText(dto.time, fallback: "刚刚"),
                ip: RemoteMapperSupport.firstNonEmpty(dto.ip, "未知 IP"),
                area: area,
                device: displayDevice(dto.network),
                statusText: "登录成功"
            )
        }
    }

    nonisolated static func mapExportStatus(_ rawValue: Int?, downloadURL: String? = nil) -> DownloadDataStatus {
        let state = DownloadExportState(rawValue: rawValue ?? 0) ?? .idle
        let message: String
        switch state {
        case .idle:
            message = "你可以随时导出个人数据副本。"
        case .exporting:
            message = "系统正在打包你的数据，请稍后回来查看。"
        case .exported:
            message = "数据已打包完成，可立即下载。"
        }

        return DownloadDataStatus(state: state, message: message, downloadURL: downloadURL)
    }

    nonisolated static func mapAvatarState(_ url: String?) -> AvatarState {
        AvatarState(url: FormValidationSupport.hasText(url ?? "") ? url : nil)
    }

    nonisolated static func makeAvatarUploadFiles(_ avatar: UploadImageAsset) -> [MultipartFormFile] {
        [
            MultipartFormFile(name: "avatar", fileName: avatar.fileName, mimeType: avatar.mimeType, data: avatar.data),
            MultipartFormFile(name: "avatar_hd", fileName: avatar.fileName, mimeType: avatar.mimeType, data: avatar.data)
        ]
    }

    nonisolated private static func maskPhone(_ phone: String?) -> String {
        guard let phone, !phone.isEmpty else { return "未绑定" }
        if phone.count >= 11 {
            let prefix = phone.prefix(3)
            let suffix = phone.suffix(4)
            return "\(prefix)****\(suffix)"
        }
        if phone.count > 4 {
            let prefix = phone.prefix(2)
            let suffix = phone.suffix(2)
            return "\(prefix)***\(suffix)"
        }
        return phone
    }

    nonisolated private static func maskEmail(_ email: String?) -> String {
        guard let email, !email.isEmpty else { return "未绑定" }
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return email }
        let local = String(parts[0])
        let domain = String(parts[1])
        let visible = String(local.prefix(3))
        return "\(visible)***@\(domain)"
    }

    nonisolated private static func displayDevice(_ rawValue: String?) -> String {
        let value = RemoteMapperSupport.firstNonEmpty(rawValue, "未知设备")
            .replacingOccurrences(of: "客户端", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = value.lowercased()

        if lowercased.contains("web") {
            return "Web"
        }
        if lowercased.contains("ipad") {
            return "iPad"
        }
        if lowercased.contains("iphone") || lowercased.contains("ios") {
            return "iPhone"
        }
        if lowercased.contains("android") {
            return "Android"
        }
        return value.isEmpty ? "未知设备" : value
    }
}
