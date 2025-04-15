//
//  Cart.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

struct Cart: Codable {
    let cart_id: Int
    let creation_date: String
    let status: String
    let status_date: String
    let user_id: Int
}
