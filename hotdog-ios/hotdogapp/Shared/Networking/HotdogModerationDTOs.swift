import Foundation

struct CursePredictionRequest: Encodable {
    let text: String
}

struct CursePredictionResponseDTO: Decodable {
    let text: String?
    let label: String?
    let result: String?
    let isCurse: Bool
    let score: Double?

    enum CodingKeys: String, CodingKey {
        case text
        case label
        case result
        case isCurse = "is_curse"
        case score
    }
}
