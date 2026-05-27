import Foundation

struct Product: Identifiable, Hashable {
    let id: UUID
    let dbSeq: Int?
    let name: String
    let category: String
    let description: String
    let price: Int
    let stockQuantity: Int
    let discountText: String
    let imageURL: String?
    let thumbnailURL: String?
    let imageBase64: String?
    let thumbnailBase64: String?

    init(
        id: UUID = UUID(),
        dbSeq: Int? = nil,
        name: String,
        category: String,
        description: String,
        price: Int,
        stockQuantity: Int,
        discountText: String,
        imageURL: String? = nil,
        thumbnailURL: String? = nil,
        imageBase64: String? = nil,
        thumbnailBase64: String? = nil
    ) {
        self.id = id
        self.dbSeq = dbSeq
        self.name = name
        self.category = category
        self.description = description
        self.price = price
        self.stockQuantity = stockQuantity
        self.discountText = discountText
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.imageBase64 = imageBase64
        self.thumbnailBase64 = thumbnailBase64
    }

    var isSoldOut: Bool {
        stockQuantity <= 0
    }
}

struct HotdogReview: Identifiable, Hashable {
    let id: UUID
    let dbSeq: Int?
    let title: String
    let author: String
    let breed: String
    let productName: String
    let summary: String
    let body: String
    let rating: Int
    let dateText: String
    var likes: Int
    let productSeq: Int?
    let userSeq: Int?
    let reviewImageURL: String?

    init(
        id: UUID = UUID(),
        dbSeq: Int? = nil,
        title: String,
        author: String,
        breed: String,
        productName: String,
        summary: String,
        body: String,
        rating: Int,
        dateText: String,
        likes: Int,
        productSeq: Int? = nil,
        userSeq: Int? = nil,
        reviewImageURL: String? = nil
    ) {
        self.id = id
        self.dbSeq = dbSeq
        self.title = title
        self.author = author
        self.breed = breed
        self.productName = productName
        self.summary = summary
        self.body = body
        self.rating = rating
        self.dateText = dateText
        self.likes = likes
        self.productSeq = productSeq
        self.userSeq = userSeq
        self.reviewImageURL = reviewImageURL
    }
}

struct DogProfile: Identifiable, Hashable {
    let id: UUID
    let dbSeq: Int?
    let name: String
    let breed: String
    let age: String
    let weight: String
    let theme: DogColorTheme
    let imageURL: String?

    init(
        id: UUID = UUID(),
        dbSeq: Int? = nil,
        name: String,
        breed: String,
        age: String,
        weight: String,
        theme: DogColorTheme,
        imageURL: String? = nil
    ) {
        self.id = id
        self.dbSeq = dbSeq
        self.name = name
        self.breed = breed
        self.age = age
        self.weight = weight
        self.theme = theme
        self.imageURL = imageURL
    }
}

struct AppNotificationItem: Identifiable, Hashable {
    let id = UUID()
    let category: String
    let title: String
    let detail: String
    var isNew: Bool
}

struct ChatbotOption: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
}

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let sender: String
    let text: String
}

struct CartItem: Identifiable, Hashable {
    let id: Product.ID
    let product: Product
    let quantity: Int
}

struct SavedAddress: Identifiable, Hashable {
    let id = UUID()
    let dbSeq: Int?
    let name: String
    let address: String
}

struct PurchaseHistoryItem: Identifiable, Hashable {
    let id = UUID()
    let dbSeq: Int?
    let product: Product?
    let productSeq: Int?
    let quantity: Int
    let totalPrice: Int
    let dateText: String
    let hasReview: Bool
    let status: PurchaseStatus
}

enum PurchaseStatus: String, Hashable {
    case shipping
    case delivered
    case confirmed
    case canceled
    case refundRequested
    case refunded

    var title: String {
        switch self {
        case .shipping:
            return "배송중"
        case .delivered:
            return "배송완료"
        case .confirmed:
            return "구매확정"
        case .canceled:
            return "주문취소"
        case .refundRequested:
            return "환불요청"
        case .refunded:
            return "환불완료"
        }
    }

    var canCancel: Bool {
        self == .shipping
    }

    var canMarkDelivered: Bool {
        self == .shipping
    }

    var canConfirmOrRefund: Bool {
        self == .delivered
    }

    var canReview: Bool {
        self == .delivered || self == .confirmed
    }
}
