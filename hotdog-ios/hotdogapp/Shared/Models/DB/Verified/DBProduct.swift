import Foundation

struct DBProduct: Identifiable, Hashable, Codable {
    let productSeq: Int
    let productName: String?
    let productQty: Int?
    let productPrice: Int?
    let productImage: Data?
    let productThumbnail: Data?
    let makerSeq: Int?
    let dogBreedsSeq: Int?
    let dogSizeSeq: Int?
    let productCategorySeq: Int?
    let productSubCategorySeq: Int?
    let dogAllergySeq: Int?
    let dogAgeSeq: Int?

    var id: Int { productSeq }
}
