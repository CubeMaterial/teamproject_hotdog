import Foundation

extension HotdogAPIClient {
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
}
