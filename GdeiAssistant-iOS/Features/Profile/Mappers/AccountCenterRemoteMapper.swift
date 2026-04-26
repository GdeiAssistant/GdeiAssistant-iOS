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
                name: RemoteMapperSupport.firstNonEmpty(dto.name, localizedString("loginRecord.unknownArea"))
            )
        }
    }

    nonisolated static func mapPhoneStatus(_ dto: PhoneStatusDTO?) -> ContactBindingStatus {
        let phone = dto?.phone?.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = dto?.code
        let note: String
        if phone == nil || phone?.isEmpty == true {
            note = localizedString("bindPhone.notBoundHint")
        } else if let code {
            note = String(format: localizedString("bindPhone.boundHint"), code)
        } else {
            note = localizedString("bindPhone.boundHintWithoutAreaCode")
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
            note: email == nil || email?.isEmpty == true
                ? localizedString("bindEmail.notBoundHint")
                : localizedString("bindEmail.boundHint"),
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
                localizedString("loginRecord.unknownArea")
            )
            return LoginRecordItem(
                id: String(dto.id ?? Int.random(in: 1...999_999)),
                timeText: RemoteMapperSupport.dateText(dto.time, fallback: localizedString("common.justNow")),
                ip: RemoteMapperSupport.firstNonEmpty(dto.ip, localizedString("loginRecord.unknownIP")),
                area: area,
                device: displayDevice(dto.network),
                statusText: localizedString("loginRecord.success")
            )
        }
    }

    nonisolated static func mapExportStatus(_ rawValue: Int?, downloadURL: String? = nil) -> DownloadDataStatus {
        let state = DownloadExportState(rawValue: rawValue ?? 0) ?? .idle
        return DownloadDataStatus(state: state, downloadURL: downloadURL)
    }

    nonisolated static func mapAvatarState(_ url: String?) -> AvatarState {
        AvatarState(url: FormValidationSupport.hasText(url ?? "") ? url : nil)
    }

    nonisolated static func mapCampusCredentialStatus(_ dto: CampusCredentialStatusDTO?) -> CampusCredentialStatus {
        let maskedAccount = SensitiveValueMasker.maskCampusAccount(
            RemoteMapperSupport.text(dto?.maskedCampusAccount)
        )
        return CampusCredentialStatus(
            hasActiveConsent: dto?.hasActiveConsent ?? false,
            hasSavedCredential: dto?.hasSavedCredential ?? false,
            quickAuthEnabled: dto?.quickAuthEnabled ?? false,
            consentedAt: sanitizedDateText(dto?.consentedAt),
            revokedAt: sanitizedDateText(dto?.revokedAt),
            policyDate: sanitizedDateText(dto?.policyDate),
            effectiveDate: sanitizedDateText(dto?.effectiveDate),
            maskedCampusAccount: maskedAccount.isEmpty ? nil : maskedAccount
        )
    }

    nonisolated static func mapCampusCredentialConsentDTO(
        _ metadata: CampusCredentialConsentMetadata
    ) -> CampusCredentialConsentRequestDTO {
        CampusCredentialConsentRequestDTO(
            scene: metadata.scene,
            policyDate: metadata.policyDate,
            effectiveDate: metadata.effectiveDate
        )
    }

    nonisolated static func mapCampusCredentialQuickAuthDTO(_ enabled: Bool) -> CampusCredentialQuickAuthRequestDTO {
        CampusCredentialQuickAuthRequestDTO(enabled: enabled)
    }

    nonisolated static func makeAvatarUploadFiles(_ avatar: UploadImageAsset) -> [MultipartFormFile] {
        [
            MultipartFormFile(name: "avatar", fileName: avatar.fileName, mimeType: avatar.mimeType, data: avatar.data),
            MultipartFormFile(name: "avatar_hd", fileName: avatar.fileName, mimeType: avatar.mimeType, data: avatar.data)
        ]
    }

    nonisolated private static func maskPhone(_ phone: String?) -> String {
        let masked = SensitiveValueMasker.maskPhone(phone)
        return masked.isEmpty ? localizedString("bindPhone.notBound") : masked
    }

    nonisolated private static func maskEmail(_ email: String?) -> String {
        let masked = SensitiveValueMasker.maskEmail(email)
        return masked.isEmpty ? localizedString("bindEmail.notBound") : masked
    }

    nonisolated private static func sanitizedDateText(_ value: RemoteFlexibleString?) -> String? {
        let text = RemoteMapperSupport.dateText(value)
        return RemoteMapperSupport.sanitizedText(text)
    }

    nonisolated private static func displayDevice(_ rawValue: String?) -> String {
        let value = RemoteMapperSupport.firstNonEmpty(rawValue, localizedString("loginRecord.unknownDevice"))
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
        return value.isEmpty ? localizedString("loginRecord.unknownDevice") : value
    }
}
