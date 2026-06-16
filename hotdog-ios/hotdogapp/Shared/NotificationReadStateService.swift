import Foundation

struct NotificationReadStateService {
    func key(for notification: AppNotificationItem) -> String {
        "\(notification.category)|\(notification.title)|\(notification.detail)"
    }

    func readKeys(forStorageKey storageKey: String) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: storageKey) ?? [])
    }

    func saveReadNotification(_ notification: AppNotificationItem, storageKey: String) {
        var keys = readKeys(forStorageKey: storageKey)
        keys.insert(key(for: notification))
        UserDefaults.standard.set(Array(keys), forKey: storageKey)
    }

    func applyReadState(to notifications: [AppNotificationItem], storageKey: String) -> [AppNotificationItem] {
        let readKeys = readKeys(forStorageKey: storageKey)
        return notifications.map { notification in
            var updated = notification
            if readKeys.contains(key(for: notification)) {
                updated.isNew = false
            }
            return updated
        }
    }
}
