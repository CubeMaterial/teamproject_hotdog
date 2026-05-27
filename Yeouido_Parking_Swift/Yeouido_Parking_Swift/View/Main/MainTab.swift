//
//  MainTab.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import Foundation

enum MainTab: Hashable {
    case home
    case map
    case facility

    var title: String {
        switch self {
        case .home:
            return "홈"
        case .map:
            return "지도"
        case .facility:
            return "시설"
        }
    }

    var symbolName: String {
        switch self {
        case .home:
            return "house.fill"
        case .map:
            return "map.fill"
        case .facility:
            return "building.2.fill"
        }
    }
}
