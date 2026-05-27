//
//  Reservation.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import Foundation

struct Reservation: Codable, Identifiable, Hashable {
    let id: Int
    let startDate: String
    let endDate: String
    let state: Int
    let reservationDate: String
    let userId: Int
    let facilityId: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "reservation_id"
        case startDate = "reservation_start_date"
        case endDate = "reservation_end_date"
        case state = "reservation_state"
        case reservationDate = "reservation_date"
        case userId = "user_id"
        case facilityId = "facility_id"
    }
}

struct ReservationDetail: Codable, Identifiable, Hashable {
    let id: Int
    let startDate: String
    let endDate: String
    let state: Int
    let reservationDate: String
    let userId: Int
    let facilityId: Int
    let facilityName: String
    let facilityInfo: String?
    let facilityImage: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "reservation_id"
        case startDate = "reservation_start_date"
        case endDate = "reservation_end_date"
        case state = "reservation_state"
        case reservationDate = "reservation_date"
        case userId = "user_id"
        case facilityId = "facility_id"
        case facilityName = "facility_name"
        case facilityInfo = "facility_info"
        case facilityImage = "facility_image"
    }
}

struct ReservationCreateRequest: Codable {
    let userId: Int
    let facilityId: Int
    let startDate: String
    let endDate: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case facilityId = "facility_id"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct DailyReservation: Codable, Identifiable, Hashable {
    let id: Int
    let startDate: String
    let endDate: String
    let state: Int
    let reservationDate: String
    let userId: Int
    let facilityId: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "reservation_id"
        case startDate = "reservation_start_date"
        case endDate = "reservation_end_date"
        case state = "reservation_state"
        case reservationDate = "reservation_date"
        case userId = "user_id"
        case facilityId = "facility_id"
    }
}
