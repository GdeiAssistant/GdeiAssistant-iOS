import Foundation

@MainActor
final class MockSpareRepository: SpareRepository {
    func queryRooms(_ query: SpareQuery) async throws -> [SpareRoomItem] {
        try await Task.sleep(nanoseconds: 180_000_000)
        _ = query
        let localeIdentifier = AppLanguage.currentIdentifier()
        return [
            SpareRoomItem(
                id: "A201",
                roomNumber: "A201",
                roomName: mockLocalizedText(simplifiedChinese: "教学楼 A201", traditionalChinese: "教學樓 A201", english: "Teaching Building A201", japanese: "講義棟 A201", korean: "강의동 A201", localeIdentifier: localeIdentifier),
                roomType: localizedString("spare.mapper.type.multimedia"),
                zoneName: localizedString("spare.mapper.zone.baiyun"),
                classSeating: "120",
                sectionText: mockLocalizedText(simplifiedChinese: "第 1-2 节", traditionalChinese: "第 1-2 節", english: "Periods 1-2", japanese: "1-2限", korean: "1-2교시", localeIdentifier: localeIdentifier),
                examSeating: "96"
            ),
            SpareRoomItem(
                id: "B305",
                roomNumber: "B305",
                roomName: mockLocalizedText(simplifiedChinese: "教学楼 B305", traditionalChinese: "教學樓 B305", english: "Teaching Building B305", japanese: "講義棟 B305", korean: "강의동 B305", localeIdentifier: localeIdentifier),
                roomType: localizedString("spare.mapper.type.classroom"),
                zoneName: localizedString("spare.mapper.zone.baiyun"),
                classSeating: "80",
                sectionText: mockLocalizedText(simplifiedChinese: "第 1-2 节", traditionalChinese: "第 1-2 節", english: "Periods 1-2", japanese: "1-2限", korean: "1-2교시", localeIdentifier: localeIdentifier),
                examSeating: "64"
            ),
            SpareRoomItem(
                id: "E402",
                roomNumber: "E402",
                roomName: mockLocalizedText(simplifiedChinese: "实验楼 E402", traditionalChinese: "實驗樓 E402", english: "Lab Building E402", japanese: "実験棟 E402", korean: "실험동 E402", localeIdentifier: localeIdentifier),
                roomType: localizedString("spare.mapper.type.computerLab"),
                zoneName: localizedString("spare.mapper.zone.baiyun"),
                classSeating: "60",
                sectionText: mockLocalizedText(simplifiedChinese: "第 1-2 节", traditionalChinese: "第 1-2 節", english: "Periods 1-2", japanese: "1-2限", korean: "1-2교시", localeIdentifier: localeIdentifier),
                examSeating: "48"
            )
        ]
    }
}
