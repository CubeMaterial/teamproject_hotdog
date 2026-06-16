import Foundation

struct ProductDTO: Decodable {
    let productSeq: Int
    let productName: String?
    let productQty: Int?
    let productPrice: Int?

    // Optional fields that backend may return via JOIN
    let productCategoryName: String?
    let productSubCategoryName: String?
    let productDescription: String?
    let makerName: String?

    // Optional image fields
    let productImageURL: String?
    let productThumbnailURL: String?
    let productImageBase64: String?
    let productThumbnailBase64: String?

    // Optional raw FK values
    let productCategorySeq: Int?
    let productSubCategorySeq: Int?

    enum CodingKeys: String, CodingKey {
        case productSeq = "product_seq"
        case productName = "product_name"
        case productQty = "product_qty"
        case productPrice = "product_price"
        case productCategoryName = "product_category_name"
        case productSubCategoryName = "product_sub_category_name"
        case productDescription = "product_description"
        case makerName = "maker_name"
        case productImageURL = "product_image_url"
        case productThumbnailURL = "product_thumbnail_url"
        case productImageBase64 = "product_image_base64"
        case productThumbnailBase64 = "product_thumbnail_base64"
        case productCategorySeq = "product_category_seq"
        case productSubCategorySeq = "product_sub_category_seq"
    }

    func toModel() -> Product {
        let resolvedName = productName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (resolvedName?.isEmpty == false) ? resolvedName! : "이름 없음"

        let fallbackImageURL = APIConfiguration.absoluteURLString(path: "/products/\(productSeq)/image")
        let fallbackThumbnailURL = APIConfiguration.absoluteURLString(path: "/products/\(productSeq)/thumbnail")

        return Product(
            dbSeq: productSeq,
            name: name,
            category: resolvedCategory(productCategoryName: productCategoryName, productSubCategoryName: productSubCategoryName),
            description: resolvedDescription(productDescription: productDescription, makerName: makerName, quantity: productQty),
            price: productPrice ?? 0,
            stockQuantity: productQty ?? 0,
            discountText: resolvedDiscountText(price: productPrice),
            imageURL: normalizedImageURL(productImageURL) ?? fallbackImageURL,
            thumbnailURL: normalizedImageURL(productThumbnailURL) ?? fallbackThumbnailURL,
            imageBase64: productImageBase64,
            thumbnailBase64: productThumbnailBase64
        )
    }

    private func resolvedCategory(productCategoryName: String?, productSubCategoryName: String?) -> String {
        let candidates = [productSubCategoryName, productCategoryName].compactMap { $0?.lowercased() }
        for value in candidates {
            if value.contains("사료") || value.contains("feed") { return "사료" }
            if value.contains("간식") || value.contains("snack") || value.contains("treat") { return "간식" }
            if value.contains("목줄") || value.contains("리드") || value.contains("리쉬") || value.contains("collar") || value.contains("leash") { return "목줄" }
            if value.contains("하네스") || value.contains("harness") { return "하네스" }
            if value.contains("의류") || value.contains("옷") || value.contains("wear") || value.contains("clothes") { return "의류" }
            if value.contains("장난감") || value.contains("toy") { return "장난감" }
        }

        let name = (productName ?? "").lowercased()
        if name.contains("사료") || name.contains("feed") { return "사료" }
        if name.contains("간식") || name.contains("treat") { return "간식" }
        if name.contains("목줄") || name.contains("리드줄") || name.contains("collar") || name.contains("leash") { return "목줄" }
        if name.contains("하네스") || name.contains("harness") { return "하네스" }
        if name.contains("의류") || name.contains("옷") || name.contains("wear") || name.contains("clothes") { return "의류" }
        if name.contains("장난감") || name.contains("toy") || name.contains("노즈워크") { return "장난감" }

        return "기타"
    }

    private func resolvedDescription(productDescription: String?, makerName: String?, quantity: Int?) -> String {
        if let productDescription, !productDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return productDescription
        }

        if let makerName, !makerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "제조사: \(makerName)"
        }

        return "재고: \(quantity ?? 0)개"
    }

    private func resolvedDiscountText(price: Int?) -> String {
        guard let price else { return "HOT" }
        if price >= 30000 { return "10%" }
        if price >= 15000 { return "BEST" }
        return "추천"
    }

    private func normalizedImageURL(_ raw: String?) -> String? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if URL(string: value)?.scheme != nil {
            return value
        }
        return APIConfiguration.absoluteURLString(path: value.hasPrefix("/") ? value : "/\(value)")
    }
}

struct ReviewDTO: Decodable {
    let reviewSeq: Int
    let productSeq: Int?
    let userSeq: Int?
    let reviewTitle: String?
    let reviewContent: String?
    let reviewImage: String?
    let reviewDate: String?
    let reviewRating: Int?
    let reviewLike: Int?
    let buySeq: Int?

    // Optional joined fields from backend query
    let productName: String?
    let userName: String?

    enum CodingKeys: String, CodingKey {
        case reviewSeq = "review_seq"
        case productSeq = "product_seq"
        case userSeq = "user_seq"
        case reviewTitle = "review_title"
        case reviewContent = "review_content"
        case reviewImage = "review_image"
        case reviewDate = "review_date"
        case reviewRating = "review_rating"
        case reviewLike = "review_like"
        case buySeq = "buy_seq"
        case productName = "product_name"
        case userName = "user_name"
    }

    func toModel(productsBySeq: [Int: Product]) -> HotdogReview {
        let mappedProductName: String = {
            if let productName, !productName.isEmpty { return productName }
            if let productSeq, let product = productsBySeq[productSeq] { return product.name }
            return "상품 정보 없음"
        }()

        let bodyText = reviewContent ?? ""
        let titleText = reviewTitle?.trimmingCharacters(in: .whitespacesAndNewlines)

        return HotdogReview(
            id: UUID(),
            dbSeq: reviewSeq,
            title: (titleText?.isEmpty == false) ? titleText! : (bodyText.isEmpty ? "리뷰" : String(bodyText.prefix(40))),
            author: userName ?? "익명",
            breed: "",
            productName: mappedProductName,
            summary: "",
            body: bodyText,
            rating: reviewRating ?? 5,
            dateText: reviewDate ?? "",
            likes: reviewLike ?? 0,
            productSeq: productSeq,
            userSeq: userSeq,
            reviewImageURL: normalizedReviewImageURL(reviewImage)
        )
    }

    private func normalizedReviewImageURL(_ raw: String?) -> String? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if URL(string: value)?.scheme != nil {
            return value
        }
        return APIConfiguration.absoluteURLString(path: value.hasPrefix("/") ? value : "/\(value)")
    }
}

struct CreateReviewRequest: Encodable {
    let productSeq: Int
    let userSeq: Int
    let buySeq: Int?
    let reviewTitle: String
    let reviewContent: String
    let reviewImage: String?
    let reviewRating: Int

    enum CodingKeys: String, CodingKey {
        case productSeq = "product_seq"
        case userSeq = "user_seq"
        case buySeq = "buy_seq"
        case reviewTitle = "review_title"
        case reviewContent = "review_content"
        case reviewImage = "review_image"
        case reviewRating = "review_rating"
    }
}

struct UpdateReviewRequest: Encodable {
    let userSeq: Int
    let reviewTitle: String
    let reviewContent: String
    let reviewImage: String?
    let reviewRating: Int

    enum CodingKeys: String, CodingKey {
        case userSeq = "user_seq"
        case reviewTitle = "review_title"
        case reviewContent = "review_content"
        case reviewImage = "review_image"
        case reviewRating = "review_rating"
    }
}
