import Combine
import CoreLocation
import Foundation
import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

struct AppNotification: Identifiable, Equatable {
    let id: UUID
    let message: String
    let createdAt: Date
    var isRead: Bool
}

final class GlobalState: ObservableObject {
    private enum StorageKey {
        static let userLoginStatus = "userLoginStatus"
        static let currentUserID = "currentUserID"
        static let currentUserEmail = "currentUserEmail"
        static let currentUserName = "currentUserName"
        static let currentUserPhone = "currentUserPhone"
        static let currentUserDate = "currentUserDate"
        static let currentUserId = "currentUserId"

        static func favoriteFacilityIDs(for userID: Int?) -> String {
            if let userID {
                return "favoriteFacilityIDs_\(userID)"
            }

            return "favoriteFacilityIDs_guest"
        }
    }

    @Published var userLoginStatus = false
    @Published var currentUserID: Int?
    @Published var currentUserEmail = ""
    @Published var currentUserName = ""
    @Published var currentUserPhone = ""
    @Published var currentUserDate = ""
    @Published var selectedMainTab: MainTab = .home
    @Published var isRoutePresented = false
    @Published var selectedParkingLot: ParkingLot?
    @Published var routeRequestID = UUID()
    @Published var selectedMapFacilityID: Int?
    @Published var mapSelectionRequestID = UUID()
    @Published var isMapFilterSheetPresented = false
    @Published var notifications: [AppNotification] = []
    @Published var favoriteFacilityIDs: Set<Int> = []

    private var chatReplyListener: ChatListenerToken?
    private var knownAdminMessageIDs: Set<String> = []
    private var hasLoadedInitialAdminMessages = false
    private var pushTokenObserver: NSObjectProtocol?

    init() {
        let defaults = UserDefaults.standard
        userLoginStatus = defaults.bool(forKey: StorageKey.userLoginStatus)
        if defaults.object(forKey: StorageKey.currentUserID) != nil {
            currentUserID = defaults.integer(forKey: StorageKey.currentUserID)
        }
        currentUserEmail = defaults.string(forKey: StorageKey.currentUserEmail) ?? ""
        currentUserName = defaults.string(forKey: StorageKey.currentUserName) ?? ""
        currentUserPhone = defaults.string(forKey: StorageKey.currentUserPhone) ?? ""
        currentUserDate = defaults.string(forKey: StorageKey.currentUserDate) ?? ""
        favoriteFacilityIDs = loadFavoriteFacilityIDs(for: currentUserID)

        requestNotificationAuthorization()
        observePushTokenUpdates()

        if userLoginStatus {
            startChatReplyListenerIfNeeded()
            syncPushTokenIfPossible()
        }
    }

    func login(email: String, name: String? = nil, phone: String? = nil, date: String? = nil, userId: Int? = nil) {
        currentUserID = userId
        currentUserEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUserName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        currentUserPhone = (phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        currentUserDate = (date ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        userLoginStatus = true
        persistUserSession()
        favoriteFacilityIDs = loadFavoriteFacilityIDs(for: userId)
        startChatReplyListenerIfNeeded()
        syncPushTokenIfPossible()
    }

    func logout() {
        currentUserID = nil
        currentUserEmail = ""
        currentUserName = ""
        currentUserPhone = ""
        currentUserDate = ""
        userLoginStatus = false
        clearUserSession()
        favoriteFacilityIDs = loadFavoriteFacilityIDs(for: nil)
        stopChatReplyListener()
    }

    deinit {
        if let pushTokenObserver {
            NotificationCenter.default.removeObserver(pushTokenObserver)
        }
    }

    func showRoute(to parkingLot: ParkingLot) {
        selectedParkingLot = parkingLot
        isRoutePresented = true
        routeRequestID = UUID()
    }

    func showFacilityOnMap(facilityID: Int) {
        selectedMapFacilityID = facilityID
        selectedMainTab = .map
        mapSelectionRequestID = UUID()
    }

    func isFavoriteFacility(_ facilityID: Int) -> Bool {
        favoriteFacilityIDs.contains(facilityID)
    }

    func toggleFavoriteFacility(_ facilityID: Int) {
        if favoriteFacilityIDs.contains(facilityID) {
            favoriteFacilityIDs.remove(facilityID)
        } else {
            favoriteFacilityIDs.insert(facilityID)
        }

        saveFavoriteFacilityIDs()
    }

    func scheduleReservationNotifications(
        reservationID: Int,
        facilityName: String,
        startDate: Date
    ) {
        removeReservationNotifications(reservationID: reservationID)

        let notificationCenter = UNUserNotificationCenter.current()
        let hourReminders: [(hoursBefore: Int, title: String)] = [
            (3, "예약 3시간 전"),
            (1, "예약 1시간 전")
        ]

        for reminder in hourReminders {
            guard let triggerDate = Calendar.current.date(byAdding: .hour, value: -reminder.hoursBefore, to: startDate),
                  triggerDate > Date() else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = "\(facilityName) 예약이 \(reminder.hoursBefore)시간 뒤에 시작됩니다."
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "reservation_\(reservationID)_\(reminder.hoursBefore)h"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            notificationCenter.add(request)
        }

        let testReminders: [(secondsBefore: TimeInterval, title: String)] = [
            (60, "예약 1분 전"),
            (30, "예약 30초 전")
        ]

        for reminder in testReminders {
            let triggerDate = startDate.addingTimeInterval(-reminder.secondsBefore)
            guard triggerDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = "\(facilityName) 예약 시작이 곧 다가옵니다."
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: triggerDate
            )

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "reservation_\(reservationID)_\(Int(reminder.secondsBefore))s"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            notificationCenter.add(request)
        }
    }

    func removeReservationNotifications(reservationID: Int) {
        let identifiers = [
            "reservation_\(reservationID)_3h",
            "reservation_\(reservationID)_1h",
            "reservation_\(reservationID)_60s",
            "reservation_\(reservationID)_30s"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    func removeNotification(_ notificationID: UUID) {
        notifications.removeAll { $0.id == notificationID }
    }

    func clearNotifications() {
        notifications.removeAll()
    }

    func markAllNotificationsAsRead() {
        notifications = notifications.map { notification in
            var updated = notification
            updated.isRead = true
            return updated
        }
    }

    private func persistUserSession() {
        let defaults = UserDefaults.standard
        defaults.set(userLoginStatus, forKey: StorageKey.userLoginStatus)
        if let currentUserID {
            defaults.set(currentUserID, forKey: StorageKey.currentUserID)
        } else {
            defaults.removeObject(forKey: StorageKey.currentUserID)
        }
        defaults.set(currentUserEmail, forKey: StorageKey.currentUserEmail)
        defaults.set(currentUserName, forKey: StorageKey.currentUserName)
        defaults.set(currentUserPhone, forKey: StorageKey.currentUserPhone)
        defaults.set(currentUserDate, forKey: StorageKey.currentUserDate)
    }

    private func clearUserSession() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: StorageKey.userLoginStatus)
        defaults.removeObject(forKey: StorageKey.currentUserID)
        defaults.removeObject(forKey: StorageKey.currentUserEmail)
        defaults.removeObject(forKey: StorageKey.currentUserName)
        defaults.removeObject(forKey: StorageKey.currentUserPhone)
        defaults.removeObject(forKey: StorageKey.currentUserDate)
    }

    private func loadFavoriteFacilityIDs(for userID: Int?) -> Set<Int> {
        let defaults = UserDefaults.standard
        let key = StorageKey.favoriteFacilityIDs(for: userID)
        let ids = defaults.array(forKey: key) as? [Int] ?? []
        return Set(ids)
    }

    private func saveFavoriteFacilityIDs() {
        let defaults = UserDefaults.standard
        let key = StorageKey.favoriteFacilityIDs(for: currentUserID)
        defaults.set(Array(favoriteFacilityIDs).sorted(), forKey: key)
    }

    private func startChatReplyListenerIfNeeded() {
        guard userLoginStatus, let currentUserID else { return }

        stopChatReplyListener()
        knownAdminMessageIDs = []
        hasLoadedInitialAdminMessages = false

        chatReplyListener = ChatFirestoreService.observeMessages(userID: currentUserID) { [weak self] messages in
            self?.handleIncomingChatMessages(messages)
        }
    }

    private func observePushTokenUpdates() {
        pushTokenObserver = NotificationCenter.default.addObserver(
            forName: .pushTokenDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let token = notification.object as? String else { return }
            self?.syncPushTokenIfPossible(token: token)
        }
    }

    private func syncPushTokenIfPossible(token: String? = nil) {
        guard userLoginStatus,
              let currentUserID,
              ChatFirestoreService.isFirebaseAvailable
        else { return }

        let resolvedToken = token
            ?? UserDefaults.standard.string(forKey: "fcmToken")
            ?? UserDefaults.standard.string(forKey: "apnsDeviceToken")

        guard let resolvedToken, !resolvedToken.isEmpty else { return }

        ChatFirestoreService.updatePushToken(
            userID: currentUserID,
            email: currentUserEmail,
            token: resolvedToken
        )
    }

    private func stopChatReplyListener() {
        chatReplyListener?.cancel()
        chatReplyListener = nil
        knownAdminMessageIDs.removeAll()
        hasLoadedInitialAdminMessages = false
    }

    private func handleIncomingChatMessages(_ messages: [ChatMessage]) {
        let adminMessages = messages.filter { $0.senderType == .admin }

        if !hasLoadedInitialAdminMessages {
            knownAdminMessageIDs = Set(adminMessages.map(\.id))
            hasLoadedInitialAdminMessages = true
            return
        }

        let newMessages = adminMessages
            .filter { !knownAdminMessageIDs.contains($0.id) }
            .sorted { $0.createdAt < $1.createdAt }

        guard !newMessages.isEmpty else { return }

        knownAdminMessageIDs.formUnion(newMessages.map(\.id))

        for message in newMessages {
            let summary = "관리자 답변: \(message.text)"
            notifications.insert(
                AppNotification(
                    id: UUID(),
                    message: summary,
                    createdAt: Date(),
                    isRead: false
                ),
                at: 0
            )
            notifications = Array(notifications.prefix(20))
            scheduleLocalNotification(for: summary)
        }
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
#if canImport(UIKit)
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
#endif
        }
    }

    private func scheduleLocalNotification(for body: String) {
        let content = UNMutableNotificationContent()
        content.title = "새 문의 답변"
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
