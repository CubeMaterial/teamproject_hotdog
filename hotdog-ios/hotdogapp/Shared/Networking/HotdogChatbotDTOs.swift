import Foundation

struct ChatMessageRequest: Encodable {
    let message: String
    let sessionID: String?
    let userSeq: Int?
    let userID: String?
    let buySeq: Int?
    let deliverSeq: Int?
    let productSeq: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case sessionID = "session_id"
        case userSeq = "user_seq"
        case userID = "user_id"
        case buySeq = "buy_seq"
        case deliverSeq = "deliver_seq"
        case productSeq = "product_seq"
    }
}

struct ChatSelectRequest: Encodable {
    let selected: String
}

struct ChatOptionsResponseDTO: Decodable {
    struct Payload: Decodable {
        let step: String?
        let options: [String]?
    }

    let success: Bool?
    let message: String?
    let data: Payload?

    var resolvedOptions: [String] {
        data?.options ?? []
    }
}

struct ChatSelectResponseDTO: Decodable {
    struct Payload: Decodable {
        let selected: String?
        let answer: String?
        let nextStep: String?
        let options: [String]?

        enum CodingKeys: String, CodingKey {
            case selected
            case answer
            case nextStep = "next_step"
            case options
        }
    }

    let success: Bool?
    let message: String?
    let data: Payload?

    var resolvedAnswer: String? {
        data?.answer ?? message
    }

    var resolvedOptions: [String] {
        data?.options ?? []
    }
}

struct ChatMessageResponseDTO: Decodable {
    struct Payload: Decodable {
        let answer: String?
        let sessionID: String?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case answer
            case sessionID = "session_id"
            case error
        }
    }

    let success: Bool?
    let message: String?
    let data: Payload?
    let answer: String?

    var resolvedAnswer: String? {
        data?.answer ?? answer ?? message
    }

    var resolvedSessionID: String? {
        data?.sessionID
    }
}
