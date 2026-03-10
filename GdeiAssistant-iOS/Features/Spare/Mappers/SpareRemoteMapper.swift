import Foundation

enum SpareRemoteMapper {
    static let zoneTitles = ["白云校区", "龙洞校区", "三水校区", "东莞校区", "外部教学点"]
    static let typeTitles = ["普通课室", "多媒体课室", "机房", "实验室", "阶梯教室", "智慧课室"]
    static let weekTypeTitles = ["全部", "单周", "双周"]

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
                roomName: RemoteMapperSupport.firstNonEmpty(dto.name, "空教室"),
                roomType: RemoteMapperSupport.firstNonEmpty(dto.type, "普通课室"),
                zoneName: RemoteMapperSupport.firstNonEmpty(dto.zone, "校区待定"),
                classSeating: RemoteMapperSupport.firstNonEmpty(dto.classSeating, "0"),
                sectionText: RemoteMapperSupport.firstNonEmpty(dto.section, "时段待定"),
                examSeating: RemoteMapperSupport.firstNonEmpty(dto.examSeating, "0")
            )
        }
    }
}
