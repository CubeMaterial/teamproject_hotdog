import Foundation

struct DBBuy: Identifiable, Hashable, Codable {
    let buySeq: Int
    let buyDate: Date?
    let buyQty: Int?
    let buyPrice: Int?
    let productSeq: Int?
    let userSeq: Int?
    let eventSeq: Int?

    var id: Int { buySeq }
}
