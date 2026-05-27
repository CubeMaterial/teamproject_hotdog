//
//  Inquiry.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 4/12/26.
//

import Foundation

struct Inquiry: Codable, Identifiable, Hashable {
    let id: Int
    let content: String
    let title: String
    let date: String
    let userId: String

    enum CodingKeys: String, CodingKey {
        case id = "inquiry_id"
        case content = "inquiry_content"
        case title = "inquiry_title"
        case date = "inquiry_date"
        case userId = "user_id"
    }
}
