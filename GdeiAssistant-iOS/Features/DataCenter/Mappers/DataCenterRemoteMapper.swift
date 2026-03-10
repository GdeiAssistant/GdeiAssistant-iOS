import Foundation

enum DataCenterRemoteMapper {
    nonisolated static func mapElectricityQuery(_ query: ElectricityQuery) -> [FormFieldValue] {
        [
            FormFieldValue(name: "name", value: FormValidationSupport.trimmed(query.name)),
            FormFieldValue(name: "number", value: FormValidationSupport.trimmed(query.studentNumber)),
            FormFieldValue(name: "year", value: String(query.year))
        ]
    }

    nonisolated static func mapElectricityBill(_ dto: ElectricityBillRemoteDTO) -> ElectricityBill {
        ElectricityBill(
            year: dto.year ?? 0,
            buildingNumber: RemoteMapperSupport.firstNonEmpty(dto.buildingNumber, "宿舍楼"),
            roomNumber: String(dto.roomNumber ?? 0),
            peopleNumber: String(dto.peopleNumber ?? 0),
            department: RemoteMapperSupport.firstNonEmpty(dto.department, "学院暂缺"),
            usedElectricAmount: String(format: "%.2f", dto.usedElectricAmount ?? 0),
            freeElectricAmount: String(format: "%.2f", dto.freeElectricAmount ?? 0),
            feeBasedElectricAmount: String(format: "%.2f", dto.feeBasedElectricAmount ?? 0),
            electricPrice: String(format: "%.2f", dto.electricPrice ?? 0),
            totalElectricBill: String(format: "%.2f", dto.totalElectricBill ?? 0),
            averageElectricBill: String(format: "%.2f", dto.averageElectricBill ?? 0)
        )
    }

    nonisolated static func mapYellowPages(_ dto: YellowPageResultRemoteDTO) -> [YellowPageCategory] {
        let grouped = Dictionary(grouping: dto.data ?? [], by: { $0.typeCode ?? 0 })
        let orderedTypes = dto.type ?? []
        var categories = [YellowPageCategory]()
        var visitedCodes = Set<Int>()

        for type in orderedTypes {
            let typeCode = type.typeCode ?? 0
            let entries = grouped[typeCode] ?? []
            guard !entries.isEmpty else { continue }
            visitedCodes.insert(typeCode)
            categories.append(
                YellowPageCategory(
                    id: String(typeCode),
                    name: RemoteMapperSupport.firstNonEmpty(type.typeName, "黄页分类"),
                    items: entries.map(mapYellowPageEntry)
                )
            )
        }

        for typeCode in grouped.keys.sorted() where !visitedCodes.contains(typeCode) {
            categories.append(
                YellowPageCategory(
                    id: String(typeCode),
                    name: RemoteMapperSupport.firstNonEmpty(grouped[typeCode]?.first?.typeName, "黄页分类"),
                    items: (grouped[typeCode] ?? []).map(mapYellowPageEntry)
                )
            )
        }

        return categories
    }

    nonisolated private static func mapYellowPageEntry(_ entry: YellowPageEntryRemoteDTO) -> YellowPageEntry {
        YellowPageEntry(
            id: String(entry.id ?? Int.random(in: 1...999_999)),
            section: RemoteMapperSupport.firstNonEmpty(entry.section, "未知部门"),
            campus: RemoteMapperSupport.firstNonEmpty(entry.campus, ""),
            majorPhone: RemoteMapperSupport.firstNonEmpty(entry.majorPhone, ""),
            minorPhone: RemoteMapperSupport.firstNonEmpty(entry.minorPhone, ""),
            address: RemoteMapperSupport.firstNonEmpty(entry.address, ""),
            email: RemoteMapperSupport.firstNonEmpty(entry.email, ""),
            website: RemoteMapperSupport.firstNonEmpty(entry.website, "")
        )
    }
}
