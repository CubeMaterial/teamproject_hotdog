import Foundation

struct ProductStorageService {
    func saveProductIDs(_ productIDs: [Product.ID], products: [Product], forKey key: String) {
        let productSeqs = productIDs.compactMap { productID in
            products.first(where: { $0.id == productID })?.dbSeq
        }
        UserDefaults.standard.set(productSeqs, forKey: key)
    }

    func saveFavoriteProductIDs(_ productIDs: Set<Product.ID>, products: [Product], forKey key: String) {
        saveProductIDs(Array(productIDs), products: products, forKey: key)
    }

    func restoreProductIDs(products: [Product], forKey key: String) -> [Product.ID] {
        let savedSeqs = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        guard !savedSeqs.isEmpty, !products.isEmpty else { return [] }

        let productsBySeq = products.reduce(into: [Int: Product]()) { result, product in
            if let dbSeq = product.dbSeq {
                result[dbSeq] = product
            }
        }
        return savedSeqs.compactMap { productsBySeq[$0]?.id }
    }

    func restoreFavoriteProductIDs(products: [Product], forKey key: String) -> Set<Product.ID> {
        Set(restoreProductIDs(products: products, forKey: key))
    }
}
