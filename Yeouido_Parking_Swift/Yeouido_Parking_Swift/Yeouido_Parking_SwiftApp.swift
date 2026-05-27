//
//  Yeouido_Parking_SwiftApp.swift
//  Yeouido_Parking_Swift
//
//  Created by MAC on 4/8/26.
//

import SwiftUI
import FirebaseCore
import UserNotifications
import UIKit
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

extension Notification.Name {
    static let pushTokenDidUpdate = Notification.Name("pushTokenDidUpdate")
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
#if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = self
#endif
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
#if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { token, error in
            if let error {
                print("FCM token fetch error: \(error.localizedDescription)")
                return
            }

            guard let token else { return }
            UserDefaults.standard.set(token, forKey: "fcmToken")
            NotificationCenter.default.post(name: .pushTokenDidUpdate, object: token)
            print("FCM token: \(token)")
        }
#else
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: "apnsDeviceToken")
        print("APNs token: \(token)")
#endif
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Remote notification registration failed: \(error.localizedDescription)")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}

#if canImport(FirebaseMessaging)
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        NotificationCenter.default.post(name: .pushTokenDidUpdate, object: fcmToken)
        print("FCM registration token refreshed: \(fcmToken)")
    }
}
#endif

@main
struct Yeouido_Parking_SwiftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var globalState = GlobalState()
    @StateObject private var parkingLocationService = ParkingLocationService()
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalState)
                .environmentObject(parkingLocationService)
                .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        }
    }
}
