//
//  Facility.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import Foundation

struct Facility: Codable, Identifiable, Hashable {
    let id: Int
    let lat: Double
    let long: Double
    let name: String
    let info: String?
    let image: String?
    let possible: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "f_id"
        case lat = "f_lat"
        case long = "f_long"
        case name = "f_name"
        case info = "f_info"
        case image = "f_image"
        case possible = "f_possible"
    }
}
