import Foundation

extension HotdogAPIClient {
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
}
