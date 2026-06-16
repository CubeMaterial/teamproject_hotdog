import Foundation

struct ReviewStateService {
    func sorted(_ reviews: [HotdogReview]) -> [HotdogReview] {
        reviews.sorted {
            if $0.likes != $1.likes {
                return $0.likes > $1.likes
            }
            return ($0.dbSeq ?? 0) > ($1.dbSeq ?? 0)
        }
    }

    func sameReview(_ lhs: HotdogReview, _ rhs: HotdogReview) -> Bool {
        if let lhsSeq = lhs.dbSeq, let rhsSeq = rhs.dbSeq {
            return lhsSeq == rhsSeq
        }
        return lhs.id == rhs.id
    }

    func likeKey(for review: HotdogReview) -> String {
        if let dbSeq = review.dbSeq {
            return "db:\(dbSeq)"
        }
        return "local:\(review.id.uuidString)"
    }

    func isAuthor(review: HotdogReview, currentUserSeq: Int?) -> Bool {
        guard let userSeq = review.userSeq, let currentUserSeq else { return false }
        return userSeq == currentUserSeq
    }

    func preservingIdentity(current: HotdogReview, updated: HotdogReview) -> HotdogReview {
        HotdogReview(
            id: current.id,
            dbSeq: updated.dbSeq,
            title: updated.title,
            author: updated.author,
            breed: updated.breed,
            productName: updated.productName,
            summary: updated.summary,
            body: updated.body,
            rating: updated.rating,
            dateText: updated.dateText,
            likes: updated.likes,
            productSeq: updated.productSeq,
            userSeq: updated.userSeq,
            reviewImageURL: updated.reviewImageURL
        )
    }
}
