import Foundation

struct DBUser: Identifiable, Hashable, Codable {
    let userSeq: Int
    let userName: String?
    let userAge: Int?
    let userPhone: String?
    let userID: String?
    let userPW: String?
    let userImage: String?
    let userDate: Date?
    let quickPinHash: String?

    var id: Int { userSeq }

    enum CodingKeys: String, CodingKey {
        case userSeq
        case userName
        case userAge
        case userPhone
        case userID = "userId"
        case userPW = "userPw"
        case userImage
        case userDate
        case quickPinHash = "quick_pin_hash"
    }
}
