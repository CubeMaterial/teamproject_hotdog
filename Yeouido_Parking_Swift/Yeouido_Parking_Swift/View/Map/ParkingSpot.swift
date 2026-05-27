//
//  ParkingSpot.swift
//  Yeouido_Parking_Swift
//

import MapKit

struct ParkingSpot: Identifiable {
    let parkingLotID: Int
    let sourceName: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let maxCapacity: Int

    var id: Int { parkingLotID }

    var shortDisplayName: String {
        "제\(parkingLotID)주차장"
    }
}

extension ParkingSpot {
    static let sampleSpots: [ParkingSpot] = [
        ParkingSpot(
            parkingLotID: 1,
            sourceName: "여의도1주차장",
            name: "여의도 제1주차장 (원효대교 남단 상류)",
            address: "서울 영등포구 여의도동 86-5",
            coordinate: CLLocationCoordinate2D(latitude: 37.522687, longitude: 126.939791),
            maxCapacity: 462
        ),
        ParkingSpot(
            parkingLotID: 2,
            sourceName: "여의도2주차장",
            name: "여의도 제2주차장 (마포대교 남단)",
            address: "서울 영등포구 여의도동 84-4",
            coordinate: CLLocationCoordinate2D(latitude: 37.528949, longitude: 126.931099),
            maxCapacity: 176
        ),
        ParkingSpot(
            parkingLotID: 3,
            sourceName: "여의도3주차장",
            name: "여의도 제3주차장 (서강대교 남단)",
            address: "서울 영등포구 여의도동 83-6",
            coordinate: CLLocationCoordinate2D(latitude: 37.532418, longitude: 126.92388),
            maxCapacity: 785
        ),
        ParkingSpot(
            parkingLotID: 4,
            sourceName: "여의도4주차장",
            name: "여의도 제4주차장 (여의교)",
            address: "서울 영등포구 여의도동 19",
            coordinate: CLLocationCoordinate2D(latitude: 37.526966, longitude: 126.912714),
            maxCapacity: 218
        ),
        ParkingSpot(
            parkingLotID: 5,
            sourceName: "여의도5주차장",
            name: "여의도 제5주차장 (샛강생태공원)",
            address: "서울 영등포구 여의도동 63",
            coordinate: CLLocationCoordinate2D(latitude: 37.516917, longitude: 126.934599),
            maxCapacity: 141
        )
    ]
}
