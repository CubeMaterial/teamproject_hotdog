//
//  Admin.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 4/12/26.
//

import Foundation

struct Admin: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let email: String
    let password: String
    let date: String

    enum CodingKeys: String, CodingKey {
        case id = "admin_id"
        case name = "admin_name"
        case email = "admin_email"
        case password = "admin_password"
        case date = "admin_date"
    }
}
