import Foundation

struct LoginRequest: Encodable {
    let userID: String
    let userPW: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userPW = "user_pw"
    }
}

struct LoginResponseDTO: Decodable {
    let userSeq: Int
    let userName: String?
    let userID: String?
    let userPhone: String?
    let quickPinHash: String?

    enum CodingKeys: String, CodingKey {
        case userSeq = "user_seq"
        case userName = "user_name"
        case userID = "user_id"
        case userPhone = "user_phone"
        case quickPinHash = "quick_pin_hash"
    }
}

struct SignUpRequest: Encodable {
    let userID: String
    let userPW: String
    let userName: String
    let userPhone: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userPW = "user_pw"
        case userName = "user_name"
        case userPhone = "user_phone"
    }
}

struct UpdateQuickPinRequest: Encodable {
    let quickPinHash: String

    enum CodingKeys: String, CodingKey {
        case quickPinHash = "quick_pin_hash"
    }
}

struct UserIDAvailabilityRequest: Encodable {
    let userID: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
    }
}

struct UserIDAvailabilityResponseDTO: Decodable {
    let available: Bool?
    let exists: Bool?
    let isDuplicate: Bool?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case available
        case exists
        case isDuplicate = "is_duplicate"
        case message
    }

    var isAvailable: Bool {
        if let available { return available }
        if let exists { return !exists }
        if let isDuplicate { return !isDuplicate }
        return false
    }
}

struct FindUserIDRequest: Encodable {
    let userName: String
    let userPhone: String

    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case userPhone = "user_phone"
    }
}

struct FindUserIDResponseDTO: Decodable {
    let userID: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case message
    }
}

struct ResetPasswordRequest: Encodable {
    let userID: String
    let userPW: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userPW = "user_pw"
    }
}

struct EmailCodeRequest: Encodable {
    let email: String
}

struct EmailCodeVerifyRequest: Encodable {
    let email: String
    let code: String
}

struct MessageResponseDTO: Decodable {
    let message: String?
    let devCode: String?
    let verificationCode: String?

    enum CodingKeys: String, CodingKey {
        case message
        case devCode = "dev_code"
        case verificationCode = "verification_code"
    }
}
