import Foundation

struct ProductCatalogService {
    func filteredProducts(_ products: [Product], searchText: String, category: String) -> [Product] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return products.filter { product in
            let matchesCategory = category == "전체" || product.category == category
            let matchesSearch = keyword.isEmpty ||
                product.name.localizedCaseInsensitiveContains(keyword) ||
                product.description.localizedCaseInsensitiveContains(keyword)
            return matchesCategory && matchesSearch
        }
        .sorted {
            if $0.isSoldOut != $1.isSoldOut {
                return !$0.isSoldOut && $1.isSoldOut
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    func favoriteProducts(_ products: [Product], favoriteProductIDs: Set<Product.ID>) -> [Product] {
        products.filter { favoriteProductIDs.contains($0.id) }
    }

    func cartItems(products: [Product], cartProductIDs: [Product.ID]) -> [CartItem] {
        let grouped = Dictionary(grouping: cartProductIDs, by: { $0 })
        return products.compactMap { product in
            guard let ids = grouped[product.id] else { return nil }
            return CartItem(id: product.id, product: product, quantity: ids.count)
        }
    }

    func productsBySeq(_ products: [Product]) -> [Int: Product] {
        products.reduce(into: [Int: Product]()) { result, product in
            if let dbSeq = product.dbSeq {
                result[dbSeq] = product
            }
        }
    }
}
