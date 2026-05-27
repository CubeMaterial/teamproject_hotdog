//
//  RealtimeParkingLog.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 4/12/26.
//

import Foundation

struct RealtimeParkingLog: Codable, Identifiable, Hashable {
    let id: Int
    let quantity: Int
    let date: String
    let parkingLotId: Int

    enum CodingKeys: String, CodingKey {
        case id = "realtime_parking_log_id"
        case quantity = "realtime_parking_log_qty"
        case date = "realtime_parking_log_date"
        case parkingLotId = "parkinglot_id"
    }
}
