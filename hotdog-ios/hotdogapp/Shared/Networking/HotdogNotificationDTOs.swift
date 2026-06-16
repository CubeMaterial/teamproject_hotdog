import Foundation

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
