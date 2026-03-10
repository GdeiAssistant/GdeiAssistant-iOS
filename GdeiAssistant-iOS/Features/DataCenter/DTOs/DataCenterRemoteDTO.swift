import Foundation

struct ElectricityBillRemoteDTO: Decodable {
    let year: Int?
    let buildingNumber: String?
    let roomNumber: Int?
    let peopleNumber: Int?
    let department: String?
    let usedElectricAmount: Double?
    let freeElectricAmount: Double?
    let feeBasedElectricAmount: Double?
    let electricPrice: Double?
    let totalElectricBill: Double?
    let averageElectricBill: Double?
}

struct YellowPageResultRemoteDTO: Decodable {
    let data: [YellowPageEntryRemoteDTO]?
    let type: [YellowPageTypeRemoteDTO]?
}

struct YellowPageTypeRemoteDTO: Decodable {
    let typeCode: Int?
    let typeName: String?
}

struct YellowPageEntryRemoteDTO: Decodable {
    let id: Int?
    let typeCode: Int?
    let typeName: String?
    let section: String?
    let campus: String?
    let majorPhone: String?
    let minorPhone: String?
    let address: String?
    let email: String?
    let website: String?
}
