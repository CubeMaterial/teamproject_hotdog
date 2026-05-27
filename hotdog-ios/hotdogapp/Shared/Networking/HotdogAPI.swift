import Foundation

enum APIConfiguration {
    // Replace with your REST API base URL (not the RDS endpoint).
    static let baseURLString = "http://127.0.0.1:8000"

    static func absoluteURLString(path: String) -> String? {
        URL(string: baseURLString)?
            .appending(path: path)
            .absoluteString
    }
}

enum DogAnalysisAPIConfiguration {
    static let baseURLString = "https://borrowing-brook-shakiness.ngrok-free.dev"
    static let apiKey = "dog-api-test-key"
}

enum ChatbotAPIConfiguration {
    static let defaultBaseURLString = "http://127.0.0.1:8001"

    static var baseURLStrings: [String] {
        let override = ProcessInfo.processInfo.environment["HOTDOG_CHATBOT_API_BASE_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [
            override?.isEmpty == false ? override : nil,
            APIConfiguration.baseURLString,
            defaultBaseURLString
        ].compactMap { $0 }

        return candidates.reduce(into: [String]()) { result, candidate in
            guard !result.contains(candidate) else { return }
            result.append(candidate)
        }
    }
}

private struct ListEnvelope<T: Decodable>: Decodable {
    let data: [T]?
    let items: [T]?
    let result: [T]?

    var values: [T] {
        data ?? items ?? result ?? []
    }
}

private struct ValueEnvelope<T: Decodable>: Decodable {
    let data: T?
    let item: T?
    let result: T?
    let user: T?

    var value: T? {
        data ?? item ?? result ?? user
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyIntIfPresent(forKey key: Key) throws -> Int? {
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(doubleValue)
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let boolValue = try? decodeIfPresent(Bool.self, forKey: key) {
            return boolValue ? 1 : 0
        }
        return nil
    }

    func decodeLossyStringIfPresent(forKey key: Key) throws -> String? {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return "\(intValue)"
        }
        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            if doubleValue.rounded() == doubleValue {
                return "\(Int(doubleValue))"
            }
            return "\(doubleValue)"
        }
        if let boolValue = try? decodeIfPresent(Bool.self, forKey: key) {
            return boolValue ? "true" : "false"
        }
        return nil
    }
}

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
            id: UUID(),
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

struct PurchaseDTO: Decodable {
    let buySeq: Int?
    let productSeq: Int?
    let buyDate: String?
    let buyQuantity: Int?
    let buyPrice: Int?
    let hasReview: Int?
    let buyStatus: String?

    enum CodingKeys: String, CodingKey {
        case buySeq = "buy_seq"
        case productSeq = "product_seq"
        case buyDate = "buy_date"
        case buyQuantity = "buy_qty"
        case buyPrice = "buy_price"
        case hasReview = "has_review"
        case buyStatus = "buy_status"
    }

    func toHistoryItem(productsBySeq: [Int: Product]) -> PurchaseHistoryItem {
        let product = productSeq.flatMap { productsBySeq[$0] }
        return PurchaseHistoryItem(
            dbSeq: buySeq,
            product: product,
            productSeq: productSeq,
            quantity: max(1, buyQuantity ?? 1),
            totalPrice: buyPrice ?? ((product?.price ?? 0) * max(1, buyQuantity ?? 1)),
            dateText: buyDate ?? "",
            hasReview: (hasReview ?? 0) > 0,
            status: resolvedStatus(from: buyStatus)
        )
    }

    private func resolvedStatus(from raw: String?) -> PurchaseStatus {
        switch (raw ?? "").lowercased() {
        case "delivered":
            return .delivered
        case "confirmed":
            return .confirmed
        case "canceled", "cancelled":
            return .canceled
        case "refund_requested", "refund requested", "refund-requested":
            return .refundRequested
        case "refunded":
            return .refunded
        default:
            return .shipping
        }
    }
}

struct CreatePurchaseItemRequest: Encodable {
    let productSeq: Int
    let quantity: Int
    let price: Int

    enum CodingKeys: String, CodingKey {
        case productSeq = "product_seq"
        case quantity
        case price
    }
}

struct CreatePurchasesRequest: Encodable {
    let items: [CreatePurchaseItemRequest]
    let address: String
    let paymentMethod: String

    enum CodingKeys: String, CodingKey {
        case items
        case address
        case paymentMethod = "payment_method"
    }
}

struct CreatePurchasesResponseDTO: Decodable {
    let buySeqList: [Int]?
    let purchases: [PurchaseDTO]?
    let data: [PurchaseDTO]?
    let items: [PurchaseDTO]?

    enum CodingKeys: String, CodingKey {
        case buySeqList = "buy_seq_list"
        case purchases
        case data
        case items
    }
}

struct PurchaseStatusUpdateRequest: Encodable {
    let action: String
}

struct AddressDTO: Decodable {
    let addressSeq: Int?
    let userSeq: Int?
    let addressName: String?
    let address: String?

    enum CodingKeys: String, CodingKey {
        case addressSeq = "address_seq"
        case userSeq = "user_seq"
        case addressName = "address_name"
        case address
    }

    func toModel() -> SavedAddress {
        SavedAddress(
            dbSeq: addressSeq,
            name: addressName ?? "배송지",
            address: address ?? ""
        )
    }
}

struct LoginRequest: Encodable {
    let userID: String
    let userPW: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userPW = "user_pw"
    }
}

struct LoginResponseDTO: Decodable {
    let userSeq: Int
    let userName: String?
    let userID: String?
    let userPhone: String?
    let quickPinHash: String?

    enum CodingKeys: String, CodingKey {
        case userSeq = "user_seq"
        case userName = "user_name"
        case userID = "user_id"
        case userPhone = "user_phone"
        case quickPinHash = "quick_pin_hash"
    }
}

struct SignUpRequest: Encodable {
    let userID: String
    let userPW: String
    let userName: String
    let userPhone: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userPW = "user_pw"
        case userName = "user_name"
        case userPhone = "user_phone"
    }
}

struct UpdateQuickPinRequest: Encodable {
    let quickPinHash: String

    enum CodingKeys: String, CodingKey {
        case quickPinHash = "quick_pin_hash"
    }
}

struct UserIDAvailabilityRequest: Encodable {
    let userID: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
    }
}

struct UserIDAvailabilityResponseDTO: Decodable {
    let available: Bool?
    let exists: Bool?
    let isDuplicate: Bool?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case available
        case exists
        case isDuplicate = "is_duplicate"
        case message
    }

    var isAvailable: Bool {
        if let available { return available }
        if let exists { return !exists }
        if let isDuplicate { return !isDuplicate }
        return false
    }
}

struct FindUserIDRequest: Encodable {
    let userName: String
    let userPhone: String

    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case userPhone = "user_phone"
    }
}

struct FindUserIDResponseDTO: Decodable {
    let userID: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case message
    }
}

struct ResetPasswordRequest: Encodable {
    let userID: String
    let userPW: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userPW = "user_pw"
    }
}

struct EmailCodeRequest: Encodable {
    let email: String
}

struct EmailCodeVerifyRequest: Encodable {
    let email: String
    let code: String
}

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

struct DogGIFGenerationResponseDTO: Decodable {
    let success: Bool?
    let jobID: String?
    let gifURL: String?

    enum CodingKeys: String, CodingKey {
        case success
        case jobID = "job_id"
        case gifURL = "gif_url"
    }
}

struct MessageResponseDTO: Decodable {
    let message: String?
    let devCode: String?
    let verificationCode: String?

    enum CodingKeys: String, CodingKey {
        case message
        case devCode = "dev_code"
        case verificationCode = "verification_code"
    }
}

struct ChatMessageRequest: Encodable {
    let message: String
    let sessionID: String?
    let userSeq: Int?
    let userID: String?
    let buySeq: Int?
    let deliverSeq: Int?
    let productSeq: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case sessionID = "session_id"
        case userSeq = "user_seq"
        case userID = "user_id"
        case buySeq = "buy_seq"
        case deliverSeq = "deliver_seq"
        case productSeq = "product_seq"
    }
}

struct ChatSelectRequest: Encodable {
    let selected: String
}

struct ChatOptionsResponseDTO: Decodable {
    struct Payload: Decodable {
        let step: String?
        let options: [String]?
    }

    let success: Bool?
    let message: String?
    let data: Payload?

    var resolvedOptions: [String] {
        data?.options ?? []
    }
}

struct ChatSelectResponseDTO: Decodable {
    struct Payload: Decodable {
        let selected: String?
        let answer: String?
        let nextStep: String?
        let options: [String]?

        enum CodingKeys: String, CodingKey {
            case selected
            case answer
            case nextStep = "next_step"
            case options
        }
    }

    let success: Bool?
    let message: String?
    let data: Payload?

    var resolvedAnswer: String? {
        data?.answer ?? message
    }

    var resolvedOptions: [String] {
        data?.options ?? []
    }
}

struct ChatMessageResponseDTO: Decodable {
    struct Payload: Decodable {
        let answer: String?
        let sessionID: String?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case answer
            case sessionID = "session_id"
            case error
        }
    }

    let success: Bool?
    let message: String?
    let data: Payload?
    let answer: String?

    var resolvedAnswer: String? {
        data?.answer ?? answer ?? message
    }

    var resolvedSessionID: String? {
        data?.sessionID
    }
}

struct DogDTO: Decodable {
    let dogSeq: Int?
    let dogName: String?
    let breedName: String?
    let ageName: String?
    let weightText: String?
    let colorName: String?
    let dogImage: String?

    enum CodingKeys: String, CodingKey {
        case dogSeq = "dog_seq"
        case dogName = "dog_name"
        case breedName = "breed_name"
        case ageName = "age_name"
        case weightText = "weight_text"
        case colorName = "color_name"
        case dogImage = "dog_image"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dogSeq = try container.decodeLossyIntIfPresent(forKey: .dogSeq)
        dogName = try container.decodeLossyStringIfPresent(forKey: .dogName)
        breedName = try container.decodeLossyStringIfPresent(forKey: .breedName)
        ageName = try container.decodeLossyStringIfPresent(forKey: .ageName)
        weightText = try container.decodeLossyStringIfPresent(forKey: .weightText)
        colorName = try container.decodeLossyStringIfPresent(forKey: .colorName)
        dogImage = try container.decodeLossyStringIfPresent(forKey: .dogImage)
    }

    func toModel() -> DogProfile {
        DogProfile(
            dbSeq: dogSeq,
            name: (dogName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? dogName! : "반려견",
            breed: (breedName?.isEmpty == false) ? breedName! : "견종 미상",
            age: (ageName?.isEmpty == false) ? ageName! : "나이 미상",
            weight: (weightText?.isEmpty == false) ? weightText! : "체중 미상",
            theme: resolvedTheme(from: colorName),
            imageURL: normalizedDogImageURL(dogImage)
        )
    }

    private func normalizedDogImageURL(_ raw: String?) -> String? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if URL(string: value)?.scheme != nil {
            return value
        }
        return APIConfiguration.absoluteURLString(path: value.hasPrefix("/") ? value : "/\(value)")
    }

    private func resolvedTheme(from raw: String?) -> DogColorTheme {
        let value = (raw ?? "").lowercased()
        if value.contains("black") || value.contains("검정") || value.contains("블랙") { return .black }
        if value.contains("gray") || value.contains("grey") || value.contains("회색") || value.contains("그레이") { return .gray }
        if value.contains("white") || value.contains("흰") || value.contains("화이트") { return .white }
        return .brown
    }
}

struct CreateDogRequest: Encodable {
    let dogName: String
    let breedName: String
    let ageName: String
    let weightText: String
    let colorName: String
    let dogImage: String?

    enum CodingKeys: String, CodingKey {
        case dogName = "dog_name"
        case breedName = "breed_name"
        case ageName = "age_name"
        case weightText = "weight_text"
        case colorName = "color_name"
        case dogImage = "dog_image"
    }
}

struct NotificationDTO: Decodable {
    let category: String?
    let title: String?
    let detail: String?
    let isNew: Int?

    enum CodingKeys: String, CodingKey {
        case category
        case title
        case detail
        case isNew = "is_new"
    }

    func toModel() -> AppNotificationItem {
        AppNotificationItem(
            category: category ?? "알림",
            title: title ?? "새 소식",
            detail: detail ?? "최근 활동이 업데이트되었습니다.",
            isNew: (isNew ?? 1) != 0
        )
    }
}

enum HotdogAPIError: LocalizedError {
    case invalidBaseURL(String)
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case transport(URLError)
    case decoding(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case let .invalidBaseURL(urlString):
            return "API 주소가 올바르지 않습니다: \(urlString)"
        case .invalidResponse:
            return "서버 응답 형식이 올바르지 않습니다."
        case let .httpError(statusCode, body):
            return "서버 오류(\(statusCode)): \(body)"
        case let .transport(error):
            return "네트워크 연결 오류: \(error.localizedDescription)"
        case let .decoding(error):
            return "응답 파싱 실패: \(error.localizedDescription)"
        case let .unknown(error):
            return "알 수 없는 오류: \(error.localizedDescription)"
        }
    }
}

struct HotdogAPIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = encoder
    }

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

    func fetchReviews(productsBySeq: [Int: Product]) async throws -> [HotdogReview] {
        let data = try await send(path: "/reviews", method: "GET")
        do {
            if let raw = try? decoder.decode([ReviewDTO].self, from: data) {
                return raw.map { $0.toModel(productsBySeq: productsBySeq) }
            }
            let wrapped = try decoder.decode(ListEnvelope<ReviewDTO>.self, from: data)
            return wrapped.values.map { $0.toModel(productsBySeq: productsBySeq) }
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func createReview(_ request: CreateReviewRequest) async throws -> ReviewDTO {
        let data = try await send(path: "/reviews", method: "POST", body: request)
        return try decodeReviewResponse(data: data)
    }

    func likeReview(reviewSeq: Int) async throws -> ReviewDTO {
        let data = try await send(path: "/reviews/\(reviewSeq)/like", method: "POST")
        return try decodeReviewResponse(data: data)
    }

    func updateReview(reviewSeq: Int, request: UpdateReviewRequest) async throws -> ReviewDTO {
        let data = try await send(path: "/reviews/\(reviewSeq)", method: "PATCH", body: request)
        return try decodeReviewResponse(data: data)
    }

    func deleteReview(reviewSeq: Int, userSeq: Int) async throws {
        _ = try await send(path: "/reviews/\(reviewSeq)/users/\(userSeq)", method: "DELETE")
    }

    private func decodeReviewResponse(data: Data) throws -> ReviewDTO {
        do {
            if let value = try? decoder.decode(ReviewDTO.self, from: data) {
                return value
            }
            let wrapped = try decoder.decode(ListEnvelope<ReviewDTO>.self, from: data)
            if let first = wrapped.values.first {
                return first
            }
            throw HotdogAPIError.invalidResponse
        } catch {
            if let apiError = error as? HotdogAPIError { throw apiError }
            throw HotdogAPIError.decoding(error)
        }
    }

    func fetchUserPurchasedProductSeqs(userSeq: Int) async throws -> [Int] {
        let data = try await send(path: "/users/\(userSeq)/purchases", method: "GET")
        do {
            if let raw = try? decoder.decode([PurchaseDTO].self, from: data) {
                return raw.compactMap(\.productSeq)
            }
            let wrapped = try decoder.decode(ListEnvelope<PurchaseDTO>.self, from: data)
            return wrapped.values.compactMap(\.productSeq)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func fetchUserPurchases(userSeq: Int, productsBySeq: [Int: Product]) async throws -> [PurchaseHistoryItem] {
        let data = try await send(path: "/users/\(userSeq)/purchases", method: "GET")
        do {
            if let raw = try? decoder.decode([PurchaseDTO].self, from: data) {
                return raw.map { $0.toHistoryItem(productsBySeq: productsBySeq) }
            }
            let wrapped = try decoder.decode(ListEnvelope<PurchaseDTO>.self, from: data)
            return wrapped.values.map { $0.toHistoryItem(productsBySeq: productsBySeq) }
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func fetchUserAddresses(userSeq: Int) async throws -> [SavedAddress] {
        let data = try await send(path: "/users/\(userSeq)/addresses", method: "GET")
        do {
            if let raw = try? decoder.decode([AddressDTO].self, from: data) {
                return raw.map { $0.toModel() }
            }
            let wrapped = try decoder.decode(ListEnvelope<AddressDTO>.self, from: data)
            return wrapped.values.map { $0.toModel() }
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func createPurchases(
        userSeq: Int,
        items: [CreatePurchaseItemRequest],
        address: String,
        paymentMethod: String
    ) async throws -> [Int] {
        let request = CreatePurchasesRequest(items: items, address: address, paymentMethod: paymentMethod)
        let data = try await send(path: "/users/\(userSeq)/purchases", method: "POST", body: request)
        do {
            if let raw = try? decoder.decode([PurchaseDTO].self, from: data) {
                return raw.compactMap(\.productSeq)
            }
            if let response = try? decoder.decode(CreatePurchasesResponseDTO.self, from: data) {
                let purchases = response.purchases ?? response.data ?? response.items ?? []
                if !purchases.isEmpty {
                    return purchases.compactMap(\.productSeq)
                }
                if response.buySeqList != nil {
                    return items.map(\.productSeq)
                }
            }
            let wrapped = try decoder.decode(ListEnvelope<PurchaseDTO>.self, from: data)
            return wrapped.values.compactMap(\.productSeq)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func login(userID: String, userPW: String) async throws -> LoginResponseDTO {
        let request = LoginRequest(userID: userID, userPW: userPW)
        do {
            return try await decodeLogin(path: "/auth/login", request: request)
        } catch let error as HotdogAPIError {
            if case let .httpError(statusCode, _) = error, statusCode == 404 {
                return try await decodeLogin(path: "/login", request: request)
            }
            throw error
        }
    }

    func signUp(
        userID: String,
        userPW: String,
        userName: String,
        userPhone: String?
    ) async throws -> LoginResponseDTO {
        let request = SignUpRequest(
            userID: userID,
            userPW: userPW,
            userName: userName,
            userPhone: userPhone
        )
        return try await decodeLogin(path: "/auth/signup", request: request)
    }

    func updateUserQuickPin(userSeq: Int, quickPinHash: String) async throws {
        let request = UpdateQuickPinRequest(quickPinHash: quickPinHash)
        do {
            _ = try await send(path: "/users/\(userSeq)/quick-pin", method: "PATCH", body: request)
        } catch let error as HotdogAPIError {
            if case let .httpError(statusCode, _) = error, statusCode == 404 {
                _ = try await send(path: "/users/\(userSeq)/pin", method: "PATCH", body: request)
                return
            }
            throw error
        }
    }

    func fetchUserProfile(userSeq: Int) async throws -> LoginResponseDTO {
        let data = try await send(path: "/users/\(userSeq)", method: "GET")
        return try decodeLoginResponse(data: data)
    }

    func checkUserIDAvailability(userID: String) async throws -> UserIDAvailabilityResponseDTO {
        let request = UserIDAvailabilityRequest(userID: userID)
        let candidates: [(path: String, method: String)] = [
            ("/auth/check-id", "POST"),
            ("/auth/check-user-id", "POST"),
            ("/users/check-id", "POST")
        ]

        var lastError: Error?
        for candidate in candidates {
            do {
                let data = try await send(path: candidate.path, method: candidate.method, body: request)
                return decodeAvailabilityResponse(from: data)
            } catch let error as HotdogAPIError {
                if case let .httpError(statusCode, body) = error {
                    if statusCode == 409 {
                        return UserIDAvailabilityResponseDTO(
                            available: false,
                            exists: true,
                            isDuplicate: true,
                            message: body.isEmpty ? "이미 사용 중인 아이디입니다." : body
                        )
                    }
                    if statusCode == 404 {
                        lastError = error
                        continue
                    }
                }
                throw error
            } catch {
                lastError = error
            }
        }

        if let lastError {
            throw lastError
        }
        throw HotdogAPIError.invalidResponse
    }

    func findUserID(userName: String, userPhone: String) async throws -> FindUserIDResponseDTO {
        let request = FindUserIDRequest(userName: userName, userPhone: userPhone)
        let data = try await send(path: "/auth/find-id", method: "POST", body: request)
        do {
            return try decoder.decode(FindUserIDResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func resetPassword(userID: String, userPW: String) async throws -> MessageResponseDTO {
        let request = ResetPasswordRequest(userID: userID, userPW: userPW)
        let data = try await send(path: "/auth/reset-password", method: "POST", body: request)
        do {
            return try decoder.decode(MessageResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func sendEmailVerificationCode(email: String) async throws -> MessageResponseDTO {
        let request = EmailCodeRequest(email: email)
        let data = try await send(path: "/auth/email/send-code", method: "POST", body: request)
        do {
            return try decoder.decode(MessageResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func verifyEmailCode(email: String, code: String) async throws -> MessageResponseDTO {
        let request = EmailCodeVerifyRequest(email: email, code: code)
        let data = try await send(path: "/auth/email/verify-code", method: "POST", body: request)
        do {
            return try decoder.decode(MessageResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func predictCurse(text: String) async throws -> CursePredictionResponseDTO {
        let request = CursePredictionRequest(text: text)
        let data = try await sendDogAnalysisAPI(path: "/curse/predict", method: "POST", body: request)
        do {
            return try decoder.decode(CursePredictionResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func generateDogGIF(imageData: Data, mcResolution: Int = 256, chunkSize: Int = 8192) async throws -> DogGIFGenerationResponseDTO {
        let queryItems = [
            URLQueryItem(name: "mc_resolution", value: "\(mcResolution)"),
            URLQueryItem(name: "chunk_size", value: "\(chunkSize)")
        ]
        let data = try await uploadDogAnalysisImage(path: "/dog3d/gif", imageData: imageData, queryItems: queryItems)
        do {
            return try decoder.decode(DogGIFGenerationResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func sendChatMessage(
        message: String,
        sessionID: String?,
        userSeq: Int?,
        userID: String?,
        buySeq: Int? = nil,
        deliverSeq: Int? = nil,
        productSeq: Int? = nil
    ) async throws -> ChatMessageResponseDTO {
        let request = ChatMessageRequest(
            message: message,
            sessionID: sessionID,
            userSeq: userSeq,
            userID: userID,
            buySeq: buySeq,
            deliverSeq: deliverSeq,
            productSeq: productSeq
        )
        let data = try await sendChatbotAPI(path: "/chat/message", method: "POST", body: request)
        do {
            return try decoder.decode(ChatMessageResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func fetchChatbotOptions() async throws -> ChatOptionsResponseDTO {
        let data = try await sendChatbotAPI(path: "/chat/options", method: "GET", body: Optional<String>.none)
        do {
            return try decoder.decode(ChatOptionsResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func selectChatbotOption(_ selected: String) async throws -> ChatSelectResponseDTO {
        let request = ChatSelectRequest(selected: selected)
        let data = try await sendChatbotAPI(path: "/chat/select", method: "POST", body: request)
        do {
            return try decoder.decode(ChatSelectResponseDTO.self, from: data)
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func fetchUserDogs(userSeq: Int) async throws -> [DogProfile] {
        let data = try await send(path: "/users/\(userSeq)/dogs", method: "GET")
        do {
            if let raw = try? decoder.decode([DogDTO].self, from: data) {
                return raw.map { $0.toModel() }
            }
            let wrapped = try decoder.decode(ListEnvelope<DogDTO>.self, from: data)
            return wrapped.values.map { $0.toModel() }
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    func createUserDog(userSeq: Int, request: CreateDogRequest) async throws -> DogProfile {
        let data = try await send(path: "/users/\(userSeq)/dogs", method: "POST", body: request)
        do {
            if let value = try? decoder.decode(DogDTO.self, from: data) {
                return value.toModel()
            }
            if let wrapped = try? decoder.decode(ValueEnvelope<DogDTO>.self, from: data),
               let value = wrapped.value {
                return value.toModel()
            }
            let wrapped = try decoder.decode(ListEnvelope<DogDTO>.self, from: data)
            if let first = wrapped.values.first {
                return first.toModel()
            }
            throw HotdogAPIError.invalidResponse
        } catch {
            if let apiError = error as? HotdogAPIError { throw apiError }
            throw HotdogAPIError.decoding(error)
        }
    }

    func updateUserDog(userSeq: Int, dogSeq: Int, request: CreateDogRequest) async throws -> DogProfile {
        let data = try await send(path: "/users/\(userSeq)/dogs/\(dogSeq)", method: "PATCH", body: request)
        do {
            if let value = try? decoder.decode(DogDTO.self, from: data) {
                return value.toModel()
            }
            if let wrapped = try? decoder.decode(ValueEnvelope<DogDTO>.self, from: data),
               let value = wrapped.value {
                return value.toModel()
            }
            let wrapped = try decoder.decode(ListEnvelope<DogDTO>.self, from: data)
            if let first = wrapped.values.first {
                return first.toModel()
            }
            throw HotdogAPIError.invalidResponse
        } catch {
            if let apiError = error as? HotdogAPIError { throw apiError }
            throw HotdogAPIError.decoding(error)
        }
    }

    func deleteUserDog(userSeq: Int, dogSeq: Int) async throws {
        _ = try await send(path: "/users/\(userSeq)/dogs/\(dogSeq)", method: "DELETE")
    }

    func updatePurchaseStatus(userSeq: Int, buySeq: Int, action: String) async throws {
        let request = PurchaseStatusUpdateRequest(action: action)
        _ = try await send(path: "/users/\(userSeq)/purchases/\(buySeq)/status", method: "PATCH", body: request)
    }

    func fetchUserNotifications(userSeq: Int) async throws -> [AppNotificationItem] {
        let data = try await send(path: "/users/\(userSeq)/notifications", method: "GET")
        do {
            if let raw = try? decoder.decode([NotificationDTO].self, from: data) {
                return raw.map { $0.toModel() }
            }
            let wrapped = try decoder.decode(ListEnvelope<NotificationDTO>.self, from: data)
            return wrapped.values.map { $0.toModel() }
        } catch {
            throw HotdogAPIError.decoding(error)
        }
    }

    private func decodeLogin(path: String, request: LoginRequest) async throws -> LoginResponseDTO {
        let data = try await send(path: path, method: "POST", body: request)
        return try decodeLoginResponse(data: data)
    }

    private func decodeLogin(path: String, request: SignUpRequest) async throws -> LoginResponseDTO {
        let data = try await send(path: path, method: "POST", body: request)
        return try decodeLoginResponse(data: data)
    }

    private func decodeLoginResponse(data: Data) throws -> LoginResponseDTO {
        do {
            if let value = try? decoder.decode(LoginResponseDTO.self, from: data) {
                return value
            }
            if let wrapped = try? decoder.decode(ValueEnvelope<LoginResponseDTO>.self, from: data),
               let value = wrapped.value {
                return value
            }
            let wrapped = try decoder.decode(ListEnvelope<LoginResponseDTO>.self, from: data)
            if let first = wrapped.values.first {
                return first
            }
            throw HotdogAPIError.invalidResponse
        } catch {
            if let apiError = error as? HotdogAPIError { throw apiError }
            throw HotdogAPIError.decoding(error)
        }
    }

    private func decodeAvailabilityResponse(from data: Data) -> UserIDAvailabilityResponseDTO {
        if let value = try? decoder.decode(UserIDAvailabilityResponseDTO.self, from: data) {
            return value
        }
        if let message = try? decoder.decode(MessageResponseDTO.self, from: data) {
            return UserIDAvailabilityResponseDTO(
                available: true,
                exists: false,
                isDuplicate: false,
                message: message.message
            )
        }
        return UserIDAvailabilityResponseDTO(
            available: true,
            exists: false,
            isDuplicate: false,
            message: "사용 가능한 아이디입니다."
        )
    }

    private func send(path: String, method: String) async throws -> Data {
        try await send(path: path, method: method, body: Optional<String>.none)
    }

    private func send<Body: Encodable>(path: String, method: String, body: Body?) async throws -> Data {
        try await send(
            path: path,
            method: method,
            body: body,
            baseURLString: APIConfiguration.baseURLString
        )
    }

    private func send<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        baseURLString: String,
        extraHeaders: [String: String] = [:],
        timeoutInterval: TimeInterval? = nil
    ) async throws -> Data {
        guard let baseURL = URL(string: baseURLString) else {
            throw HotdogAPIError.invalidBaseURL(baseURLString)
        }

        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        extraHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw HotdogAPIError.transport(urlError)
        } catch {
            throw HotdogAPIError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HotdogAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "응답 본문 없음"
            throw HotdogAPIError.httpError(statusCode: httpResponse.statusCode, body: bodyText)
        }

        return data
    }

    private func sendChatbotAPI<Body: Encodable>(path: String, method: String, body: Body?) async throws -> Data {
        var lastError: Error?

        for baseURLString in ChatbotAPIConfiguration.baseURLStrings {
            do {
                return try await send(
                    path: path,
                    method: method,
                    body: body,
                    baseURLString: baseURLString,
                    extraHeaders: ["ngrok-skip-browser-warning": "true"],
                    timeoutInterval: 150
                )
            } catch {
                lastError = error
            }
        }

        throw lastError ?? HotdogAPIError.invalidBaseURL(ChatbotAPIConfiguration.defaultBaseURLString)
    }

    private func sendDogAnalysisAPI<Body: Encodable>(path: String, method: String, body: Body?) async throws -> Data {
        guard let baseURL = URL(string: DogAnalysisAPIConfiguration.baseURLString) else {
            throw HotdogAPIError.invalidBaseURL(DogAnalysisAPIConfiguration.baseURLString)
        }

        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue(DogAnalysisAPIConfiguration.apiKey, forHTTPHeaderField: "x-api-key")

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw HotdogAPIError.transport(urlError)
        } catch {
            throw HotdogAPIError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HotdogAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "응답 본문 없음"
            throw HotdogAPIError.httpError(statusCode: httpResponse.statusCode, body: bodyText)
        }

        return data
    }

    private func uploadDogAnalysisImage(path: String, imageData: Data, queryItems: [URLQueryItem]) async throws -> Data {
        guard let baseURL = URL(string: DogAnalysisAPIConfiguration.baseURLString) else {
            throw HotdogAPIError.invalidBaseURL(DogAnalysisAPIConfiguration.baseURLString)
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        let url = baseURL.appending(path: path).appending(queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue(DogAnalysisAPIConfiguration.apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = multipartImageBody(
            imageData: imageData,
            boundary: boundary,
            fieldName: "image",
            filename: "dog.jpg"
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw HotdogAPIError.transport(urlError)
        } catch {
            throw HotdogAPIError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HotdogAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "응답 본문 없음"
            throw HotdogAPIError.httpError(statusCode: httpResponse.statusCode, body: bodyText)
        }

        return data
    }

    private func multipartImageBody(imageData: Data, boundary: String, fieldName: String, filename: String) -> Data {
        var body = Data()
        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n")
        body.appendUTF8("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendUTF8("\r\n")
        body.appendUTF8("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func appendUTF8(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
