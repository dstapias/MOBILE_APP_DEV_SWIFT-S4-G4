//
//  Order.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation

// 1. Añade : Identifiable, Equatable
struct Order: Codable, Identifiable, Equatable {

    // 2. Define 'id' para Identifiable usando 'order_id'
    var id: Int { order_id }

    let order_id: Int
    let cart_id: Int
    let status: String
    let total_price: Double
    let user_id: Int
    let creation_date: String? // String? es Equatable
    let billed_date: String?   // String? es Equatable
    let enabled: Bool?         // Bool? es Equatable
}
