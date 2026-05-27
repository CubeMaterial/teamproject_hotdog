import SwiftUI

enum AppRoute: Hashable {
    case auth
    case sessionLock
    case dogOnboarding
    case main
}

enum AppTab: Hashable {
    case home
    case products
    case walk
    case chatbot
    case notifications
    case myPage

    var title: String {
        switch self {
        case .home:
            return "홈"
        case .products:
            return "제품"
        case .walk:
            return "산책"
        case .chatbot:
            return "챗봇"
        case .notifications:
            return "알림"
        case .myPage:
            return "마이"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house.fill"
        case .products:
            return "bag.fill"
        case .walk:
            return "figure.walk"
        case .chatbot:
            return "message.fill"
        case .notifications:
            return "bell.fill"
        case .myPage:
            return "person.crop.circle.fill"
        }
    }
}
