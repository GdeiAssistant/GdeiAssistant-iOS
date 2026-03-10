import Foundation

struct CollectionSearchResponseDTO: Decodable {
    let sumPage: Int?
    let collectionList: [CollectionItemDTO]?
}

struct CollectionItemDTO: Decodable {
    let bookname: String?
    let author: String?
    let publishingHouse: String?
    let detailURL: String?
}

struct CollectionDistributionDTO: Decodable {
    let location: String?
    let callNumber: String?
    let barcode: String?
    let state: String?
}

struct CollectionDetailDTO: Decodable {
    let collectionDistributionList: [CollectionDistributionDTO]?
    let bookname: String?
    let author: String?
    let principal: String?
    let publishingHouse: String?
    let price: String?
    let physicalDescriptionArea: String?
    let personalPrincipal: String?
    let subjectTheme: String?
    let chineseLibraryClassification: String?
}

struct CollectionBorrowDTO: Decodable {
    let id: String?
    let sn: String?
    let code: String?
    let name: String?
    let author: String?
    let borrowDate: String?
    let returnDate: String?
    let renewTime: Int?
}
