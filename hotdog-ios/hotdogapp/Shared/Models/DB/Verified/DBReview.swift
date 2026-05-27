import Foundation

struct DBReview: Identifiable, Hashable, Codable {
    let reviewSeq: Int
    let productSeq: Int?
    let userSeq: Int?
    let reviewContent: String?
    let reviewImage: String?
    let reviewDate: Date?

    var id: Int { reviewSeq }
}
