import Foundation

@MainActor
final class MockDataCenterRepository: DataCenterRepository {
    func queryElectricity(_ query: ElectricityQuery) async throws -> ElectricityBill {
        try await Task.sleep(nanoseconds: 180_000_000)
        guard FormValidationSupport.hasText(query.name), FormValidationSupport.hasText(query.studentNumber) else {
            throw NetworkError.server(code: 400, message: "请完整填写姓名和学号")
        }
        return ElectricityBill(year: query.year, buildingNumber: "11 栋", roomNumber: "503", peopleNumber: "4", department: "信息工程学院", usedElectricAmount: "128.50", freeElectricAmount: "30.00", feeBasedElectricAmount: "98.50", electricPrice: "0.68", totalElectricBill: "66.98", averageElectricBill: "16.75")
    }

    func fetchYellowPages() async throws -> [YellowPageCategory] {
        try await Task.sleep(nanoseconds: 120_000_000)
        return [
            YellowPageCategory(id: "1", name: "教务服务", items: [
                YellowPageEntry(id: "y_1", section: "教务处值班室", campus: "白云校区", majorPhone: "020-12345678", minorPhone: "", address: "行政楼 302", email: "jwc@gdei.edu.cn", website: "https://www.gdei.edu.cn/jwc"),
                YellowPageEntry(id: "y_2", section: "课程中心", campus: "白云校区", majorPhone: "020-12345679", minorPhone: "", address: "行政楼 305", email: "course@gdei.edu.cn", website: ""),
                YellowPageEntry(id: "y_3", section: "考务办公室", campus: "白云校区", majorPhone: "020-12345680", minorPhone: "020-12345681", address: "行政楼 306", email: "exam@gdei.edu.cn", website: "")
            ]),
            YellowPageCategory(id: "2", name: "后勤服务", items: [
                YellowPageEntry(id: "y_4", section: "宿舍报修", campus: "白云校区", majorPhone: "020-87654321", minorPhone: "", address: "后勤楼 1 楼", email: "repair@gdei.edu.cn", website: ""),
                YellowPageEntry(id: "y_5", section: "水电报障", campus: "花都校区", majorPhone: "020-87654322", minorPhone: "", address: "后勤服务中心", email: "houqin@gdei.edu.cn", website: ""),
                YellowPageEntry(id: "y_6", section: "校园保卫处", campus: "白云校区", majorPhone: "020-87654323", minorPhone: "020-87654324", address: "保卫处值班室", email: "", website: "")
            ]),
            YellowPageCategory(id: "3", name: "学生服务", items: [
                YellowPageEntry(id: "y_7", section: "学生工作部", campus: "白云校区", majorPhone: "020-66554411", minorPhone: "", address: "行政楼 201", email: "xgb@gdei.edu.cn", website: ""),
                YellowPageEntry(id: "y_8", section: "心理咨询中心", campus: "白云校区", majorPhone: "020-66554412", minorPhone: "", address: "学生活动中心 2 楼", email: "psy@gdei.edu.cn", website: ""),
                YellowPageEntry(id: "y_9", section: "就业指导中心", campus: "花都校区", majorPhone: "020-66554413", minorPhone: "", address: "创新创业楼", email: "job@gdei.edu.cn", website: "https://job.gdei.edu.cn")
            ]),
            YellowPageCategory(id: "4", name: "图书与网络", items: [
                YellowPageEntry(id: "y_10", section: "图书馆总服务台", campus: "白云校区", majorPhone: "020-99887711", minorPhone: "", address: "图书馆 1 楼", email: "library@gdei.edu.cn", website: "https://lib.gdei.edu.cn"),
                YellowPageEntry(id: "y_11", section: "网络信息中心", campus: "白云校区", majorPhone: "020-99887712", minorPhone: "020-99887713", address: "信息楼 402", email: "nic@gdei.edu.cn", website: "https://nic.gdei.edu.cn")
            ])
        ]
    }
}
