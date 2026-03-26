import Foundation

enum SpareRemoteMapper {
    static var zoneTitles: [String] {
        [
        localizedString("spare.mapper.zone.baiyun"),
        localizedString("spare.mapper.zone.longdong"),
        localizedString("spare.mapper.zone.sanshui"),
        localizedString("spare.mapper.zone.dongguan"),
        localizedString("spare.mapper.zone.external")
        ]
    }
    static var typeTitles: [String] {
        [
        localizedString("spare.mapper.type.classroom"),
        localizedString("spare.mapper.type.multimedia"),
        localizedString("spare.mapper.type.computerLab"),
        localizedString("spare.mapper.type.laboratory"),
        localizedString("spare.mapper.type.lectureHall"),
        localizedString("spare.mapper.type.smartClassroom")
        ]
    }
    static var weekTypeTitles: [String] {
        [
        localizedString("spare.mapper.weekType.all"),
        localizedString("spare.mapper.weekType.odd"),
        localizedString("spare.mapper.weekType.even")
        ]
    }

    nonisolated static func mapQuery(_ query: SpareQuery) -> SpareQueryRemoteDTO {
        SpareQueryRemoteDTO(
            zone: query.zone,
            type: query.type,
            minSeating: query.minSeating,
            maxSeating: query.maxSeating,
            startTime: query.startTime,
            endTime: query.endTime,
            minWeek: query.minWeek,
            maxWeek: query.maxWeek,
            weekType: query.weekType,
            classNumber: query.classNumber
        )
    }

    nonisolated static func mapItems(_ dtos: [SpareRoomRemoteDTO]) -> [SpareRoomItem] {
        dtos.map { dto in
            let number = RemoteMapperSupport.firstNonEmpty(dto.number, UUID().uuidString)
            return SpareRoomItem(
                id: number,
                roomNumber: number,
                roomName: RemoteMapperSupport.firstNonEmpty(dto.name, localizedString("spare.mapper.emptyRoomName")),
                roomType: RemoteMapperSupport.firstNonEmpty(dto.type, localizedString("spare.mapper.defaultRoomType")),
                zoneName: RemoteMapperSupport.firstNonEmpty(dto.zone, localizedString("spare.mapper.defaultZone")),
                classSeating: RemoteMapperSupport.firstNonEmpty(dto.classSeating, "0"),
                sectionText: RemoteMapperSupport.firstNonEmpty(dto.section, localizedString("spare.mapper.defaultSection")),
                examSeating: RemoteMapperSupport.firstNonEmpty(dto.examSeating, "0")
            )
        }
    }
}
