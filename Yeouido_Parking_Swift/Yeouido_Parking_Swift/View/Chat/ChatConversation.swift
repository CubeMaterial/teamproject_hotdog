import Foundation

struct ChatConversation: Identifiable, Codable, Hashable {
    let id: String
    let userID: Int
    let userEmail: String
    let userName: String
    let status: String
    let createdAt: Date
    let updatedAt: Date
    let lastMessage: String
}
