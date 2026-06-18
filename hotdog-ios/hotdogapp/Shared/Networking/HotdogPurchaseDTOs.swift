import Foundation

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
    let refundReason: String?

    enum CodingKeys: String, CodingKey {
        case action
        case refundReason = "refund_reason"
    }
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
