import Foundation

struct CollectionSearchPage: Equatable {
    let items: [CollectionSearchItem]
    let sumPage: Int
}

struct CollectionSearchItem: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let publisher: String
    let detailURL: String
}

struct CollectionDistributionItem: Identifiable, Hashable {
    let id: String
    let location: String
    let callNumber: String
    let barcode: String
    let state: String
}

struct CollectionDetailInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let principal: String
    let publisher: String
    let price: String
    let physicalDescription: String
    let subjectTheme: String
    let classification: String
    let distributions: [CollectionDistributionItem]
}

struct CollectionBorrowItem: Identifiable, Hashable {
    let id: String
    let sn: String
    let code: String
    let title: String
    let author: String
    let borrowDate: String
    let returnDate: String
    let renewCount: Int
}
