//
//  ParkingLot.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import CoreLocation
import Foundation

struct ParkingLot: Identifiable, Equatable {
    let id: Int
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

extension ParkingLot {
    static func == (lhs: ParkingLot, rhs: ParkingLot) -> Bool {
        lhs.id == rhs.id
    }
}

extension ParkingLot {
    static let yeouidoLots: [ParkingLot] = [
        ParkingLot(
            id: 1,
            name: "여의도1주차장",
            address: "서울 영등포구 여의도동 86-5",
            coordinate: CLLocationCoordinate2D(latitude: 37.522752, longitude: 126.9395997)
        ),
        ParkingLot(
            id: 2,
            name: "여의도2주차장",
            address: "서울 영등포구 여의도동 84-4",
            coordinate: CLLocationCoordinate2D(latitude: 37.5290743, longitude: 126.9309679)
        ),
        ParkingLot(
            id: 3,
            name: "여의도3주차장",
            address: "서울 영등포구 여의도동 83-6",
            coordinate: CLLocationCoordinate2D(latitude: 37.532383, longitude: 126.9236764)
        ),
        ParkingLot(
            id: 4,
            name: "여의도4주차장",
            address: "서울 영등포구 여의도동 19",
            coordinate: CLLocationCoordinate2D(latitude: 37.526247, longitude: 126.9131567)
        ),
        ParkingLot(
            id: 5,
            name: "여의도5주차장",
            address: "서울 영등포구 여의도동 63",
            coordinate: CLLocationCoordinate2D(latitude: 37.5169565, longitude: 126.9349005)
        )
    ]
}
