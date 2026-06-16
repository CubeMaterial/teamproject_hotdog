import Foundation

struct UserSession: Codable {
    let userSeq: Int
    let userName: String?
    let userID: String
    let userPhone: String?
    let quickPinHash: String?
}

struct SessionStorageService {
    private enum Key {
        static let session = "hotdog_user_session"
        static let guestCart = "hotdog_cart_guest_product_seqs"
        static let guestFavorites = "hotdog_favorite_guest_product_seqs"
        static let guestReadNotifications = "hotdog_read_notifications_guest"

        static func dogOnboarding(userSeq: Int) -> String {
            "hotdog_dog_onboarding_pending_\(userSeq)"
        }

        static func cart(userSeq: Int) -> String {
            "hotdog_cart_product_seqs_\(userSeq)"
        }

        static func favorites(userSeq: Int) -> String {
            "hotdog_favorite_product_seqs_\(userSeq)"
        }

        static func readNotifications(userSeq: Int) -> String {
            "hotdog_read_notifications_\(userSeq)"
        }

        static func selectedDog(userSeq: Int) -> String {
            "hotdog_selected_dog_seq_\(userSeq)"
        }
    }

    func restoreSession() -> UserSession? {
        guard let data = UserDefaults.standard.data(forKey: Key.session) else { return nil }
        return try? JSONDecoder().decode(UserSession.self, from: data)
    }

    func saveSession(_ session: UserSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: Key.session)
    }

    func removeSession() {
        UserDefaults.standard.removeObject(forKey: Key.session)
    }

    func setDogOnboardingPending(_ pending: Bool, for userSeq: Int) {
        UserDefaults.standard.set(pending, forKey: Key.dogOnboarding(userSeq: userSeq))
    }

    func isDogOnboardingPending(for userSeq: Int) -> Bool {
        UserDefaults.standard.bool(forKey: Key.dogOnboarding(userSeq: userSeq))
    }

    func saveSelectedDogSeq(_ dogSeq: Int, for userSeq: Int) {
        UserDefaults.standard.set(dogSeq, forKey: Key.selectedDog(userSeq: userSeq))
    }

    func selectedDogSeq(for userSeq: Int) -> Int? {
        let key = Key.selectedDog(userSeq: userSeq)
        guard UserDefaults.standard.object(forKey: key) != nil else { return nil }
        return UserDefaults.standard.integer(forKey: key)
    }

    func cartKey(for userSeq: Int?) -> String {
        if let userSeq { return Key.cart(userSeq: userSeq) }
        return Key.guestCart
    }

    func favoritesKey(for userSeq: Int?) -> String {
        if let userSeq { return Key.favorites(userSeq: userSeq) }
        return Key.guestFavorites
    }

    func readNotificationsKey(for userSeq: Int?) -> String {
        if let userSeq { return Key.readNotifications(userSeq: userSeq) }
        return Key.guestReadNotifications
    }
}
