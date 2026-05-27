//
//  User.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 4/12/26.
//

import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: Int
    let email: String
    let password: String
    let date: String
    let name: String?
    let phone: String

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case email = "user_email"
        case password = "user_password"
        case date = "user_date"
        case name = "user_name"
        case phone = "user_phone"
    }
}
