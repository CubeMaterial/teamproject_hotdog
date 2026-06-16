import Foundation

extension HotdogAPIClient {
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

    func updatePurchaseStatus(userSeq: Int, buySeq: Int, action: String) async throws {
        let request = PurchaseStatusUpdateRequest(action: action)
        _ = try await send(path: "/users/\(userSeq)/purchases/\(buySeq)/status", method: "PATCH", body: request)
    }
}
