//
//  MapSearchResult.swift
//  Yeouido_Parking_Swift
//

import Foundation

enum MapSearchResult: Identifiable {
    case parking(ParkingSpot)
    case facility(MapFacility)

    var id: String {
        switch self {
        case .parking(let parkingSpot):
            return "parking-\(parkingSpot.id)"
        case .facility(let facility):
            return "facility-\(facility.id)"
        }
    }

    var title: String {
        switch self {
        case .parking(let parkingSpot):
            return parkingSpot.name
        case .facility(let facility):
            return facility.name
        }
    }

    var categoryText: String {
        switch self {
        case .parking:
            return "주차장"
        case .facility(let facility):
            if facility.isReservable {
                return "예약 가능 시설"
            }

            return facility.category?.rawValue ?? "기타 시설"
        }
    }
}
