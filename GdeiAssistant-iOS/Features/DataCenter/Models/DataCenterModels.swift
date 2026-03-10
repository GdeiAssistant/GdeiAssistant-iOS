import Foundation

struct ElectricityQuery: Equatable {
    var year: Int = Calendar.current.component(.year, from: Date())
    var name = ""
    var studentNumber = ""

    static var yearOptions: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(stride(from: currentYear, through: 2016, by: -1))
    }
}

struct ElectricityBill: Equatable {
    let year: Int
    let buildingNumber: String
    let roomNumber: String
    let peopleNumber: String
    let department: String
    let usedElectricAmount: String
    let freeElectricAmount: String
    let feeBasedElectricAmount: String
    let electricPrice: String
    let totalElectricBill: String
    let averageElectricBill: String
}

struct YellowPageEntry: Identifiable, Hashable {
    let id: String
    let section: String
    let campus: String
    let majorPhone: String
    let minorPhone: String
    let address: String
    let email: String
    let website: String
}

struct YellowPageCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let items: [YellowPageEntry]
}
