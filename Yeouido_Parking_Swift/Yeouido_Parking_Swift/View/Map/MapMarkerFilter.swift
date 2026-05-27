//
//  MapMarkerFilter.swift
//  Yeouido_Parking_Swift
//

import Foundation
import SwiftUI

enum MapMarkerFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case parking = "주차장"
    case reservableFacility = "예약 가능"
    case favoriteFacility = "즐겨찾기"
    case performance = "공연"
    case culture = "문화"
    case park = "공원"
    case food = "식음"
    case convenience = "편의"
    case otherFacility = "기타"

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .all:
            return Color.green
        case .parking:
            return Color.red
        case .reservableFacility:
            return Color.orange
        case .favoriteFacility:
            return Color(hex: "ED9781")
        case .performance:
            return Color(hex: "9B6DFF")
        case .culture:
            return Color(hex: "4E7BFF")
        case .park:
            return Color(hex: "39A96B")
        case .food:
            return Color(hex: "F08A24")
        case .convenience:
            return Color(hex: "4BA3A7")
        case .otherFacility:
            return Color(hex: "63C9F2")
        }
    }
}
