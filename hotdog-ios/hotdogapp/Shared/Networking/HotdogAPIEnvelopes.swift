import Foundation

struct ListEnvelope<T: Decodable>: Decodable {
    let data: [T]?
    let items: [T]?
    let result: [T]?

    var values: [T] {
        data ?? items ?? result ?? []
    }
}

struct ValueEnvelope<T: Decodable>: Decodable {
    let data: T?
    let item: T?
    let result: T?
    let user: T?

    var value: T? {
        data ?? item ?? result ?? user
    }
}
