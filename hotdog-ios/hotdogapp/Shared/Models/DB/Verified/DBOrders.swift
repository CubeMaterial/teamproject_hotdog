import Foundation

struct DBOrders: Identifiable, Hashable, Codable {
    let orderSeq: Int
    let warehouseSeq: Int?
    let makerSeq: Int?
    let staffSeq: Int?
    let productSeq: Int?
    let orderDate: Date?
    let orderQty: Int?
    let orderPrice: Int?
    let orderDone: Int?

    var id: Int { orderSeq }
}
