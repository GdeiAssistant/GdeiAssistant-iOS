import Foundation

@MainActor
final class MockSpareRepository: SpareRepository {
    func queryRooms(_ query: SpareQuery) async throws -> [SpareRoomItem] {
        try await Task.sleep(nanoseconds: 180_000_000)
        _ = query
        return [
            SpareRoomItem(id: "A201", roomNumber: "A201", roomName: "教学楼 A201", roomType: "多媒体课室", zoneName: "白云校区", classSeating: "120", sectionText: "第 1-2 节", examSeating: "96"),
            SpareRoomItem(id: "B305", roomNumber: "B305", roomName: "教学楼 B305", roomType: "普通课室", zoneName: "白云校区", classSeating: "80", sectionText: "第 1-2 节", examSeating: "64"),
            SpareRoomItem(id: "E402", roomNumber: "E402", roomName: "实验楼 E402", roomType: "机房", zoneName: "白云校区", classSeating: "60", sectionText: "第 1-2 节", examSeating: "48")
        ]
    }
}
