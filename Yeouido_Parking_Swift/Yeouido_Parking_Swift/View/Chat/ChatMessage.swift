import Foundation

enum ChatSenderType: String, Codable {
    case user
    case admin
}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let senderType: ChatSenderType
    let senderUserID: Int
    let createdAt: Date
}
