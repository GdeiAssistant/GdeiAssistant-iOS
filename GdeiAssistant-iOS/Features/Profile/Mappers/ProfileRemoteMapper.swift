import Foundation

enum ProfileRemoteMapperError: LocalizedError {
    case unsupportedCollege(String)
    case invalidGrade(String)
    case invalidBirthday(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedCollege(let college):
            return "当前院系“\(college)”暂不支持同步到服务端，请使用系统支持的院系名称"
        case .invalidGrade(let grade):
            return "入学年份“\(grade)”无法解析为服务端需要的年份"
        case .invalidBirthday(let birthday):
            return "生日“\(birthday)”格式无效，请重新选择"
        }
    }
}

struct ProfileRemoteUpdatePlan {
    let nickname: NicknameUpdateDTO
    let faculty: FacultyUpdateDTO
    let major: MajorUpdateDTO?
    let enrollment: EnrollmentUpdateDTO
    let introduction: IntroductionUpdateDTO
    let birthday: BirthdayUpdateDTO?
    let location: LocationUpdateDTO?
    let hometown: LocationUpdateDTO?
}

enum ProfileRemoteMapper {
    static func mapProfile(_ dto: UserProfileDTO) -> UserProfile {
        UserProfile(
            id: dto.username,
            username: dto.username,
            nickname: trimmed(dto.nickname),
            avatarURL: trimmed(dto.avatar),
            college: trimmed(dto.faculty),
            major: trimmed(dto.major),
            grade: trimmed(dto.enrollment),
            bio: trimmed(dto.introduction),
            birthday: trimmed(dto.birthday),
            location: trimmed(dto.location),
            hometown: trimmed(dto.hometown),
            ipArea: trimmed(dto.ipArea)
        )
    }

    static func mapLocationRegions(_ dtos: [ProfileLocationRegionDTO]) -> [ProfileLocationRegion] {
        dtos.compactMap { region in
            guard let regionCode = sanitized(region.code), let regionName = sanitized(region.name) ?? sanitized(region.aliasesName) else {
                return nil
            }

            let states = (region.stateMap ?? [:])
                .values
                .compactMap { state -> ProfileLocationState? in
                    guard let stateCode = sanitized(state.code), let stateName = sanitized(state.name) ?? sanitized(state.aliasesName) else {
                        return nil
                    }

                    let cities = (state.cityMap ?? [:])
                        .values
                        .compactMap { city -> ProfileLocationCity? in
                            guard let cityCode = sanitized(city.code), let cityName = sanitized(city.name) ?? sanitized(city.aliasesName) else {
                                return nil
                            }
                            return ProfileLocationCity(code: cityCode, name: cityName)
                        }
                        .sorted(by: localizedChineseOrder)

                    return ProfileLocationState(code: stateCode, name: stateName, cities: cities)
                }
                .sorted(by: localizedChineseOrder)

            return ProfileLocationRegion(code: regionCode, name: regionName, states: states)
        }
        .sorted(by: localizedChineseOrder)
    }

    static func mapProfileOptions(_ dto: ProfileOptionsDTO) -> ProfileOptions {
        let faculties = (dto.faculties ?? []).compactMap { faculty -> ProfileFacultyOption? in
            guard let code = faculty.code, let label = sanitized(faculty.label) else {
                return nil
            }

            let majors = (faculty.majors ?? [])
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            return ProfileFacultyOption(
                code: code,
                label: label,
                majors: majors.isEmpty ? [ProfileFormSupport.unselectedOption] : majors
            )
        }

        let defaultOptions = ProfileFormSupport.defaultOptions

        return ProfileOptions(
            faculties: faculties.isEmpty ? defaultOptions.faculties : faculties,
            marketplaceItemTypes: mapDictionaryOptions(dto.marketplaceItemTypes, fallback: defaultOptions.marketplaceItemTypes),
            lostFoundItemTypes: mapDictionaryOptions(dto.lostFoundItemTypes, fallback: defaultOptions.lostFoundItemTypes),
            lostFoundModes: mapDictionaryOptions(dto.lostFoundModes, fallback: defaultOptions.lostFoundModes)
        )
    }

    static func makeUpdatePlan(from request: ProfileUpdateRequest, options: ProfileOptions) throws -> ProfileRemoteUpdatePlan {
        guard let facultyCode = facultyCode(for: request.college, options: options) else {
            throw ProfileRemoteMapperError.unsupportedCollege(request.college)
        }

        let normalizedGrade = normalizeOptionalSelection(request.grade)
        let enrollmentYear = try enrollmentYear(from: normalizedGrade)

        return ProfileRemoteUpdatePlan(
            nickname: NicknameUpdateDTO(nickname: request.nickname),
            faculty: FacultyUpdateDTO(faculty: facultyCode),
            major: majorDTO(from: request.major),
            enrollment: EnrollmentUpdateDTO(year: enrollmentYear),
            introduction: IntroductionUpdateDTO(introduction: request.bio),
            birthday: try birthdayDTO(from: request.birthday),
            location: locationDTO(from: request.location),
            hometown: locationDTO(from: request.hometown)
        )
    }

    static func facultyCode(for college: String, options: ProfileOptions) -> Int? {
        options.facultyCode(for: college)
    }

    static func enrollmentYear(from grade: String?) throws -> Int? {
        guard let grade = grade, !grade.isEmpty else { return nil }

        let pattern = #"\d{4}"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(
                in: grade,
                range: NSRange(grade.startIndex..<grade.endIndex, in: grade)
            ),
            let range = Range(match.range, in: grade)
        else {
            throw ProfileRemoteMapperError.invalidGrade(grade)
        }

        return Int(grade[range])
    }

    private static func majorDTO(from major: String) -> MajorUpdateDTO? {
        let normalized = normalizeOptionalSelection(major)
        guard let normalized, !normalized.isEmpty else { return nil }
        return MajorUpdateDTO(major: normalized)
    }

    private static func birthdayDTO(from birthday: String) throws -> BirthdayUpdateDTO? {
        let normalized = birthday.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let parts = normalized.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let date = Int(parts[2]) else {
            throw ProfileRemoteMapperError.invalidBirthday(birthday)
        }

        return BirthdayUpdateDTO(year: year, month: month, date: date)
    }

    private static func locationDTO(from selection: ProfileLocationSelection?) -> LocationUpdateDTO? {
        guard let selection, !selection.regionCode.isEmpty else { return nil }
        return LocationUpdateDTO(
            region: selection.regionCode,
            state: selection.stateCode.isEmpty ? nil : selection.stateCode,
            city: selection.cityCode.isEmpty ? nil : selection.cityCode
        )
    }

    private static func trimmed(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func sanitized(_ value: String?) -> String? {
        let trimmed = trimmed(value)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func mapDictionaryOptions(
        _ values: [ProfileDictionaryOptionDTO]?,
        fallback: [ProfileDictionaryOption]
    ) -> [ProfileDictionaryOption] {
        let mapped = (values ?? []).compactMap { option -> ProfileDictionaryOption? in
            guard let code = option.code, let label = sanitized(option.label) else {
                return nil
            }
            return ProfileDictionaryOption(code: code, label: label)
        }
        return mapped.isEmpty ? fallback : mapped
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{3000}", with: "")
    }

    private static func normalizeOptionalSelection(_ value: String) -> String? {
        let trimmedValue = trimmed(value)
        if trimmedValue.isEmpty || trimmedValue == ProfileFormSupport.unselectedOption {
            return nil
        }
        return trimmedValue
    }

    nonisolated private static func localizedChineseOrder<T>(_ lhs: T, _ rhs: T) -> Bool {
        let lhsName: String
        let rhsName: String

        switch (lhs, rhs) {
        case let (left as ProfileLocationRegion, right as ProfileLocationRegion):
            lhsName = left.name
            rhsName = right.name
        case let (left as ProfileLocationState, right as ProfileLocationState):
            lhsName = left.name
            rhsName = right.name
        case let (left as ProfileLocationCity, right as ProfileLocationCity):
            lhsName = left.name
            rhsName = right.name
        default:
            return false
        }

        return lhsName.compare(
            rhsName,
            options: [],
            range: nil,
            locale: Locale(identifier: "zh_CN")
        ) == .orderedAscending
    }
}
