import Foundation

struct DBFavorites: Identifiable, Hashable, Codable {
    let favoritesSeq: Int
    let userSeq: Int?
    let productSeq: Int?

    var id: Int { favoritesSeq }
}
