//
//  User.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let mobileNumber: String
    let email: String
    let areaId: Int
    let userType: String
    let description: String?
    let verificationCode: Int

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name
        case mobileNumber = "mobile_number"
        case email = "user_email"
        case areaId = "area_id"
        case userType = "user_type"
        case description
        case verificationCode = "verification_code"
    }
}
