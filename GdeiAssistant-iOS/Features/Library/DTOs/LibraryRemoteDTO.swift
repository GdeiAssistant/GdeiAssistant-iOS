import Foundation

struct BookSearchResponseDTO: Decodable {
    let collectionList: [LibraryCollectionDTO]?
    let sumPage: Int?
}

struct LibraryCollectionDTO: Decodable {
    let bookname: String?
    let author: String?
    let publishingHouse: String?
    let detailURL: String?
}

struct LibraryCollectionDistributionDTO: Decodable {
    let location: String?
    let callNumber: String?
    let barcode: String?
    let state: String?
}

struct LibraryCollectionDetailDTO: Decodable {
    let collectionDistributionList: [LibraryCollectionDistributionDTO]?
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

struct BorrowBookDTO: Decodable {
    let id: String?
    let sn: String?
    let code: String?
    let name: String?
    let author: String?
    let borrowDate: RemoteFlexibleString?
    let returnDate: RemoteFlexibleString?
    let renewTime: Int?
}

struct LibraryRenewRequestDTO: Codable {
    let sn: String
    let code: String
    let password: String
}
