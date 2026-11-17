import Foundation

enum ProfileRemoteMapperError: LocalizedError {
    case unsupportedCollege(String)
    case invalidGrade(String)
    case invalidBirthday(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedCollege(let college):
            return String(format: localizedString("profile.mapper.unsupportedCollege"), college)
        case .invalidGrade(let grade):
            return String(format: localizedString("profile.mapper.invalidGrade"), grade)
        case .invalidBirthday(let birthday):
            return String(format: localizedString("profile.mapper.invalidBirthday"), birthday)
        }
    }
}

enum ProfileRemoteMapper {
    private static let enrollmentYearRegex = try! NSRegularExpression(pattern: #"\d{4}"#)

    static func mapProfile(_ dto: UserProfileDTO) -> UserProfile {
        let locationSelection = selection(from: dto.location)
        let hometownSelection = selection(from: dto.hometown)
        let options = ProfileFormSupport.defaultOptions
        let collegeCode = dto.facultyCode
        let majorCode = sanitized(dto.majorCode)
        let collegeLabel = options.faculties.first(where: { $0.code == collegeCode })?.label ?? ""
        let majorLabel = options.majorLabel(for: collegeLabel, majorCode: majorCode ?? "") ?? ""

        return UserProfile(
            id: dto.username,
            username: dto.username,
            nickname: trimmed(dto.nickname),
            avatarURL: trimmed(dto.avatar),
            college: collegeLabel,
            collegeCode: collegeCode,
            major: majorLabel,
            majorCode: majorCode,
            grade: trimmed(dto.enrollment),
            bio: trimmed(dto.introduction),
            birthday: trimmed(dto.birthday),
            location: locationSelection?.displayName ?? "",
            locationSelection: locationSelection,
            hometown: hometownSelection?.displayName ?? "",
            hometownSelection: hometownSelection,
            ipArea: trimmed(dto.ipArea)
        )
    }

    static func mapLocationRegions(_ dtos: [ProfileLocationRegionDTO]) -> [ProfileLocationRegion] {
        dtos.compactMap { region in
            guard let regionCode = sanitized(region.code),
                  let localizedRegion = ProfileLocationCatalog.regions.first(where: { $0.code == regionCode }) else {
                return nil
            }

            let states = (region.children ?? [])
                .compactMap { state -> ProfileLocationState? in
                    guard let stateCode = sanitized(state.code),
                          let localizedState = localizedRegion.states.first(where: { $0.code == stateCode }) else {
                        return nil
                    }

                    let cities = (state.children ?? [])
                        .compactMap { city -> ProfileLocationCity? in
                            guard let cityCode = sanitized(city.code),
                                  let localizedCity = localizedState.cities.first(where: { $0.code == cityCode }) else {
                                return nil
                            }
                            return ProfileLocationCity(code: cityCode, name: localizedCity.name)
                        }
                        .sorted(by: localizedChineseOrder)

                    return ProfileLocationState(code: stateCode, name: localizedState.name, cities: cities)
                }
                .sorted(by: localizedChineseOrder)

            return ProfileLocationRegion(code: regionCode, name: localizedRegion.name, states: states)
        }
        .sorted(by: localizedChineseOrder)
    }

    static func mapProfileOptions(_ dto: ProfileOptionsDTO) -> ProfileOptions {
        let defaultOptions = ProfileFormSupport.defaultOptions
        let faculties = (dto.faculties ?? []).compactMap { faculty -> ProfileFacultyOption? in
            guard let code = faculty.code,
                  let fallbackFaculty = defaultOptions.faculties.first(where: { $0.code == code }) else {
                return nil
            }

            let majors = (faculty.majors ?? [])
                .compactMap { majorCode in
                    fallbackFaculty.majors.first(where: { $0.code == majorCode })
                }

            return ProfileFacultyOption(
                code: code,
                label: fallbackFaculty.label,
                majors: majors.isEmpty ? makeFallbackMajorOptions() : majors
            )
        }

        return ProfileOptions(
            faculties: faculties.isEmpty ? defaultOptions.faculties : faculties,
            marketplaceItemTypes: mapDictionaryOptions(dto.marketplaceItemTypes, fallback: defaultOptions.marketplaceItemTypes),
            lostFoundItemTypes: mapDictionaryOptions(dto.lostFoundItemTypes, fallback: defaultOptions.lostFoundItemTypes),
            lostFoundModes: mapDictionaryOptions(dto.lostFoundModes, fallback: defaultOptions.lostFoundModes)
        )
    }

    static func makePatchDTO(from request: ProfileUpdateRequest) throws -> ProfilePatchDTO {
        guard request.facultyCode >= 0 else {
            throw ProfileRemoteMapperError.unsupportedCollege(String(request.facultyCode))
        }

        let normalizedMajor = sanitized(request.majorCode).flatMap { code in
            code == "unselected" ? nil : code
        }

        return ProfilePatchDTO(
            nickname: request.nickname,
            faculty: request.facultyCode,
            major: normalizedMajor,
            enrollment: request.enrollment,
            introduction: request.bio,
            birthday: try birthdayDTO(from: request.birthday),
            location: locationDTO(from: request.location),
            hometown: locationDTO(from: request.hometown)
        )
    }

    static func facultyCode(for college: String, options: ProfileOptions) -> Int? {
        options.facultyCode(for: college)
    }

    static func enrollmentYear(from grade: String?) throws -> Int? {
        guard let grade = sanitized(grade) else { return nil }

        guard
            let match = enrollmentYearRegex.firstMatch(
                in: grade,
                range: NSRange(grade.startIndex..<grade.endIndex, in: grade)
            ),
            let range = Range(match.range, in: grade)
        else {
            throw ProfileRemoteMapperError.invalidGrade(grade)
        }

        return Int(grade[range])
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

    private static func mapDictionaryOptions(_ values: [Int]?, fallback: [ProfileDictionaryOption]) -> [ProfileDictionaryOption] {
        let mapped = (values ?? []).compactMap { code in
            fallback.first(where: { $0.code == code })
        }
        return mapped.isEmpty ? fallback : mapped
    }

    private static func selection(from dto: ProfileRemoteLocationValueDTO?) -> ProfileLocationSelection? {
        guard let dto, let regionCode = sanitized(dto.regionCode) else {
            return nil
        }
        return ProfileLocationCatalog.selection(regionCode: regionCode, stateCode: trimmed(dto.stateCode), cityCode: trimmed(dto.cityCode))
    }

    private static func makeFallbackMajorOptions() -> [ProfileMajorOption] {
        [ProfileMajorOption(code: "unselected", label: ProfileFormSupport.unselectedOption)]
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
            locale: AppLanguage.locale(for: UserPreferences.currentLocale)
        ) == .orderedAscending
    }
}
