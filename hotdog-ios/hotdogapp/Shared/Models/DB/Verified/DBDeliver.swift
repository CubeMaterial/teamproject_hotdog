import Foundation

struct DBDeliver: Identifiable, Hashable, Codable {
    let deliverSeq: Int
    let userSeq: Int?
    let buySeq: Int?
    let staffSeq: Int?
    let deliverStartDate: Date?
    let deliverEndDate: Date?

    var id: Int { deliverSeq }
}
