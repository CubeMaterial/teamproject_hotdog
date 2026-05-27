//
//  ParkingLotModel.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 4/12/26.
//

import Foundation

struct ParkingLotModel: Codable, Identifiable, Hashable {
    let id: Int
    let lat: Double
    let long: Double
    let name: String
    let max: Int

    enum CodingKeys: String, CodingKey {
        case id = "parkinglot_id"
        case lat = "parkinglot_lat"
        case long = "parkinglot_long"
        case name = "parkinglot_name"
        case max = "parkinglot_max"
    }
}
