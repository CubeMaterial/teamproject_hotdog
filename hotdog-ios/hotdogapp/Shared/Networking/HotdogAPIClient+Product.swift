import Foundation

extension HotdogAPIClient {
    func fetchProducts() async throws -> [Product] {
        let data = try await send(path: "/products", method: "GET")
        do {
            if let raw = try? decoder.decode([ProductDTO].self, from: data) {
                return raw.map { $0.toModel() }
            }
            let wrapped = try decoder.decode(ListEnvelope<ProductDTO>.self, from: data)
            return wrapped.values.map { $0.toModel() }
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }
}
